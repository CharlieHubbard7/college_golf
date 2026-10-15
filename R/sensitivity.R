# Sensitivity grid for the momentum coefficient.
#
# Refits the paper's model (M1) and the primary model (M3: day form + skill by par type) under
# each alternative analysis choice, with the fast approximation (nAGQ = 0) used in the simulation, so the simulated bias
# applies to these estimates.
#
# Choices made inside R on the primary table:
#   - transitions: add the 9->10 pair (17 per round), and the 18->1 pair (18 per round)
#   - hole difficulty: the paper's definition (player's own score included in the field average)
# Choices that change the sample (tables written by 02_momentum_analysis.ipynb, data/clean/variants/):
#   - match events included, fields of 4+, extreme rounds excluded, players with 20+ rounds,
#     9-hole flat cards restored
#
# Usage (from the project root):  Rscript R/sensitivity.R [cores]
# Output: data/clean/momentum_sensitivity.csv

args <- commandArgs(trailingOnly = TRUE)
CORES <- if (length(args) >= 1) as.integer(args[1]) else 4

source("R/momentum_functions.R")
suppressPackageStartupMessages(library(parallel))

mt <- read_model_table("data/clean/momentum_model_table.parquet")
within <- c("within_nine")
specs <- list(
  list(variant = "primary",                       data = "primary", transitions = within,                                  diff = "difficulty"),
  list(variant = "+ 9->10 pair (17 per round)",   data = "primary", transitions = c(within, "nine_turn"),                  diff = "difficulty"),
  list(variant = "+ 18->1 pair (18 per round)",   data = "primary", transitions = c(within, "nine_turn", "wrap_18_to_1"),  diff = "difficulty"),
  list(variant = "paper's field average (own score included)", data = "primary", transitions = within, diff = "difficulty_incl")
)
variant_files <- c("match_events_included" = "dual/match events included",
                   "fields_4plus"           = "fields of 4+ players",
                   "extreme_rounds_excluded" = "extreme rounds excluded",
                   "players_20plus_rounds"   = "players with 20+ rounds",
                   "flat_cards_restored"     = "9-hole flat cards restored")
for (f in names(variant_files))
  specs[[length(specs) + 1]] <- list(variant = variant_files[[f]], data = f, transitions = within, diff = "difficulty")

jobs <- expand.grid(spec = seq_along(specs), gender = c("Men", "Women"), k = names(OUTCOMES),
                    re = c("player", "par_type"), stringsAsFactors = FALSE)

load_data <- function(name) {
  if (name == "primary") return(mt)
  read_model_table(file.path("data/clean/variants", paste0(name, ".parquet")))
}

t0 <- Sys.time()
out <- mclapply(seq_len(nrow(jobs)), function(i) {
  j <- jobs[i, ]; s <- specs[[j$spec]]
  d <- load_data(s$data)
  d <- droplevels(d[d$team_gender == j$gender & d$transition %in% s$transitions, ])
  fit <- fit_model(d, j$k, re = j$re, nAGQ = 0, diff_col = s$diff)
  data.frame(variant = s$variant, gender = j$gender, outcome = OUTCOMES[[j$k]],
             model = RE_LABEL[[j$re]],
             rounds = nlevels(d$player_round), players = nlevels(d$player), prev_coef(fit, j$k))
}, mc.cores = CORES, mc.preschedule = FALSE)
bad <- vapply(out, inherits, logical(1), "try-error")
if (any(bad)) stop("sensitivity fit failed: ", as.character(out[[which(bad)[1]]]))
res <- do.call(rbind, out)
write.csv(res, "data/clean/momentum_sensitivity.csv", row.names = FALSE)
cat(sprintf("wrote data/clean/momentum_sensitivity.csv: %d fits in %.1f min\n", nrow(res),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
