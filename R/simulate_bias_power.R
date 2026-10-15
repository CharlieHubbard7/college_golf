# Bias and power simulation for the momentum coefficient.
#
# For each gender and outcome:
#   1. fit the chosen model to the real data to get realistic fixed effects and random-effect
#      variances (the data-generating process, DGP);
#   2. simulate complete 18-hole rounds for the real players on the real holes, in their real
#      order, from that model, with a known momentum effect delta (0 = no momentum);
#   3. refit and record the momentum estimate.
#
# delta = 0 measures each estimator's bias when there is no momentum; delta > 0 measures the
# power of the bias-corrected test.
#
# Usage (from the project root):
#   Rscript R/simulate_bias_power.R player_round 30 15 4   # M2 DGP: bias of M1 and M2, and power
#   Rscript R/simulate_bias_power.R par_type     12  0 4   # M3 DGP: bias of M3 (null only)
# Arguments: model, simulations with delta = 0, simulations per delta > 0, parallel workers.
# Output: data/clean/momentum_simulation.csv (player_round) or momentum_simulation_m3.csv (par_type)

args <- commandArgs(trailingOnly = TRUE)
MODEL  <- if (length(args) >= 1) args[1] else "player_round"
N_NULL <- if (length(args) >= 2) as.integer(args[2]) else 30
N_ALT  <- if (length(args) >= 3) as.integer(args[3]) else 15
CORES  <- if (length(args) >= 4) as.integer(args[4]) else 4
DELTAS <- c(0.025, 0.05, 0.10)
OUT    <- if (MODEL == "player_round") "data/clean/momentum_simulation.csv" else "data/clean/momentum_simulation_m3.csv"

source("R/momentum_functions.R")
suppressPackageStartupMessages(library(parallel))
RNGkind("L'Ecuyer-CMRG")
set.seed(20261015)

mt <- read_model_table("data/clean/momentum_model_table.parquet")
results <- list()
for (g in c("Men", "Women")) {
  d18 <- droplevels(subset(mt, team_gender == g))
  stopifnot(all(d18$hole_number == rep(1:18, nrow(d18) / 18)))
  dw <- droplevels(subset(d18, transition == "within_nine"))
  for (k in names(OUTCOMES)) {
    dgp <- dgp_from_fit(fit_model(dw, k, re = MODEL, nAGQ = 0))
    cat(sprintf("%s %s (%s DGP): beta = %s, player SDs = %s, sd_round = %.3f\n", g, k, MODEL,
                paste(round(dgp$beta, 3), collapse = " "),
                paste(round(sqrt(diag(dgp$sigma_player)), 3), collapse = " "), dgp$sd_round))

    jobs <- data.frame(delta = 0, rep = seq_len(N_NULL))
    if (N_ALT > 0) jobs <- rbind(jobs, expand.grid(delta = DELTAS, rep = seq_len(N_ALT)))
    t0 <- Sys.time()
    out <- mclapply(seq_len(nrow(jobs)), function(i) {
      s <- simulate_rounds(d18, dgp, jobs$delta[i])
      own <- fit_sim(s, MODEL)
      m1 <- if (MODEL == "player_round" && jobs$delta[i] == 0) fit_sim(s, "player") else c(estimate = NA, se = NA)
      data.frame(gender = g, outcome = OUTCOMES[[k]], dgp = MODEL, delta = jobs$delta[i], rep = jobs$rep[i],
                 base_rate = mean(s$y), m1_estimate = m1[["estimate"]], m1_se = m1[["se"]],
                 estimate = own[["estimate"]], se = own[["se"]])
    }, mc.cores = CORES, mc.set.seed = TRUE, mc.preschedule = FALSE)
    bad <- vapply(out, inherits, logical(1), "try-error")
    if (any(bad)) stop("simulation failed: ", as.character(out[[which(bad)[1]]]))
    results[[paste(g, k)]] <- do.call(rbind, out)
    write.csv(do.call(rbind, results), sub("\\.csv$", "_partial.csv", OUT), row.names = FALSE)
    cat(sprintf("  %d simulations in %.1f min\n", nrow(jobs), as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }
}
res <- do.call(rbind, results)
write.csv(res, OUT, row.names = FALSE)
unlink(sub("\\.csv$", "_partial.csv", OUT))
cat("wrote", OUT, ":", nrow(res), "rows\n")
