# Shared functions for the birdie/bogey momentum models (Elmore & Urbaczewski 2018 style).
# Used by notebooks/02_momentum_analysis.ipynb (%%R cells) and the scripts in R/.
# Base R only: data.table must not be used inside the notebook's embedded R (it kills the kernel).

suppressPackageStartupMessages({
  library(lme4)
  library(arrow)
})

OUTCOMES <- c(bob = "BoB", bow = "BoW")

# Read the modelling table written by 02_momentum_analysis.ipynb, with factor ids added.
read_model_table <- function(path) {
  mt <- as.data.frame(read_parquet(path))
  mt$player <- factor(mt$player_id)
  mt$player_round <- factor(mt$round_id)
  mt
}

# Random-effect structures, from the paper's model to the primary model:
#   "player"       M1  (1 | player)                                  skill (the paper)
#   "player_round" M2  (1 | player) + (1 | player_round)             + day form
#   "par_type"     M3  (1 + par4 + par5 | player) + (1 | player_round) + skill that differs by par type
RE_LABEL <- c(player = "M1", player_round = "M2", par_type = "M3")

random_terms <- function(re, slope_term = NULL) {
  player <- if (re == "par_type") "(1 + par4 + par5 | player)"
            else if (!is.null(slope_term)) paste0("(1 + ", slope_term, " | player)")
            else "(1 | player)"
  c(player, if (re %in% c("player_round", "par_type")) "(1 | player_round)")
}

# Model formula.
#   k:        "bob" or "bow"
#   re:       "player", "player_round" or "par_type" (see above)
#   extra:    extra fixed-effect terms, e.g. c("prev:par4", "prev:par5")
#   slope:    TRUE adds a random player slope on the previous-hole indicator
#   diff_col: column used for hole difficulty
model_formula <- function(k, re = c("player", "player_round", "par_type"), extra = character(0), slope = FALSE,
                          diff_col = "difficulty") {
  re <- match.arg(re)
  prev <- paste0("prev_", k)
  fixed <- c(diff_col, prev, "par4", "par5", gsub("prev", prev, extra, fixed = TRUE))
  rand <- random_terms(re, if (slope) prev)
  as.formula(paste(k, "~", paste(c(fixed, rand), collapse = " + ")))
}

# Fit one model. nAGQ = 0 is the fast approximation used for exploration and simulation;
# nAGQ = 1 (Laplace) is used for every reported estimate.
fit_model <- function(d, k, re = "player", nAGQ = 1, ...) {
  glmer(model_formula(k, re, ...), data = d, family = binomial, nAGQ = nAGQ,
        control = glmerControl(optimizer = "bobyqa", calc.derivs = FALSE))
}

# The previous-hole coefficient, its SE, and the random-effect SDs of a fitted model.
prev_coef <- function(fit, k) {
  co <- summary(fit)$coefficients
  nm <- paste0("prev_", k)
  vc <- as.data.frame(VarCorr(fit))
  sd_of <- function(g) { x <- vc$sdcor[vc$grp == g & is.na(vc$var2) & vc$var1 == "(Intercept)"]; if (length(x)) x else NA_real_ }
  data.frame(estimate = co[nm, 1], se = co[nm, 2],
             sd_player = sd_of("player"), sd_player_round = sd_of("player_round"),
             aic = AIC(fit), bic = BIC(fit), n = nobs(fit),
             singular = isSingular(fit), stringsAsFactors = FALSE)
}

# ---- simulation -----------------------------------------------------------------------------
# The parameters a simulation needs from a fitted model: fixed effects (without the momentum
# term), the player covariance matrix (1x1 or 3x3 for intercept, par4, par5) and the
# player-round SD.
dgp_from_fit <- function(fit) {
  fe <- fixef(fit)
  vc <- VarCorr(fit)
  list(beta = unname(fe[c("(Intercept)", "difficulty", "par4", "par5")]),
       sigma_player = as.matrix(vc$player[, , drop = FALSE]),
       sd_round = attr(vc$player_round, "stddev")[[1]])
}

# Simulate outcomes for every round of `d18` (all 18 holes per round, in card order) from a
# model with player effects (an intercept, or intercept + par-4 + par-5 effects), player-round
# intercepts, and a true momentum effect `delta` (log-odds) applied on within-nine transitions
# only, exactly the transitions the analysis uses. The real holes, in their real order, are
# used, so any artifact of course layout is reproduced in the simulation.
simulate_rounds <- function(d18, dgp, delta) {
  n_round <- nrow(d18) / 18
  stopifnot(n_round == round(n_round))
  S <- dgp$sigma_player
  # matrix square root via eigen decomposition: works for the singular (positive semi-definite)
  # covariances that boundary fits produce, where chol() fails
  e <- eigen(S, symmetric = TRUE)
  root <- t(e$vectors %*% diag(sqrt(pmax(e$values, 0)), nrow(S)))
  z <- matrix(rnorm(nlevels(d18$player) * nrow(S)), ncol = nrow(S)) %*% root
  pid <- as.integer(d18$player)
  u <- z[pid, 1]
  if (nrow(S) == 3) u <- u + z[pid, 2] * d18$par4 + z[pid, 3] * d18$par5
  v <- rnorm(n_round, 0, dgp$sd_round)
  beta <- dgp$beta
  eta <- beta[1] + beta[2] * d18$difficulty + beta[3] * d18$par4 + beta[4] * d18$par5 + u
  eta <- matrix(eta, nrow = n_round, ncol = 18, byrow = TRUE) + v
  y <- matrix(0L, n_round, 18)
  for (h in 1:18) {
    lin <- eta[, h]
    if (!(h %in% c(1, 10))) lin <- lin + delta * y[, h - 1]
    y[, h] <- rbinom(n_round, 1, plogis(lin))
  }
  prev <- cbind(0L, y[, -18])
  keep <- rep(!(1:18 %in% c(1, 10)), times = n_round)       # within-nine rows, as in the analysis
  out <- d18[keep, c("player", "player_round", "difficulty", "par4", "par5")]
  out$y <- as.vector(t(y))[keep]
  out$prev_y <- as.vector(t(prev))[keep]
  out
}

# Fit M1, M2 or M3 to simulated data (fast approximation) and return the momentum estimate.
fit_sim <- function(s, re) {
  f <- as.formula(paste("y ~ difficulty + prev_y + par4 + par5 +", paste(random_terms(re), collapse = " + ")))
  fit <- glmer(f, data = s, family = binomial, nAGQ = 0,
               control = glmerControl(optimizer = "bobyqa", calc.derivs = FALSE))
  co <- summary(fit)$coefficients
  c(estimate = co["prev_y", 1], se = co["prev_y", 2])
}
