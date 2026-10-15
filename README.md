# Hot and cold hands in D3 college golf

A college-golf version of Elmore & Urbaczewski (2018), *Hot and Cold Hands on the PGA Tour: Do
they Exist?* (`references/`). The question: is a player more likely to make a birdie or better
after a birdie or better (hot hand), or a bogey or worse after a bogey or worse (cold hand),
once hole difficulty that day, par and the player are accounted for?

Data: NCAA Division III hole-by-hole scores, 2023-24 to 2025-26 seasons, men and women.

## Layout

```text
notebooks/
  01_cleaning.ipynb           raw file -> clean, tested hole and round tables
  02_momentum_analysis.ipynb  replication of the paper: data construction, Tables 1-3, Figure 1,
                              birdie/bogey mixed models in R (M1 paper, M2 + day form),
                              bias/power simulation, sensitivity grid; poster figures P1-P3
  03_strokes_gained_poster.ipynb  strokes-gained carry-over, day-form shuffle test; poster figures and text
R/
  momentum_functions.R        model formulas, fitting and simulation helpers (sourced by 02)
  simulate_bias_power.R       bias and power simulation (parallel; run from 02, cached)
  sensitivity.R               sensitivity grid (parallel; run from 02, cached)
poster/
  figures/                    M*, R* from 03 and P* from 02 (300-dpi PNG + PDF)
  POSTER_TEXT.md              paste-ready text for every poster box
data/
  raw/     d3_data.csv (source, not in git)
  clean/   outputs of the notebooks (not in git)
references/  the paper
archive/     earlier notebooks and outputs (strokes-gained approach), kept for reference
environment.yml
```

## Running

The models run in R inside `02_momentum_analysis.ipynb` (`%%R` cells via `rpy2`). One-time
setup: install R 4.5+ from CRAN, then in R run
`install.packages(c("lme4", "arrow", "broom.mixed"))`. Do not use `data.table` in the `%%R`
cells; it crashes the kernel (see section 7 of the notebook).

```bash
conda env create -f environment.yml    # once; env name: ds (includes rpy2)
conda activate ds
jupyter nbconvert --to notebook --execute --inplace notebooks/01_cleaning.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/02_momentum_analysis.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/03_strokes_gained_poster.ipynb
```

Each notebook stops on the first failed test. `01` writes `data/clean/d3_clean_holes.parquet`
(the input to `02`) plus a per-round audit of every dropped round; `02` writes
`data/clean/momentum_model_table.parquet`, one row per hole with outcomes, previous-hole
indicators, difficulty and par dummies.

## Status

- [x] Cleaning: round-level checks, field and course detection, duplicates within and across
      events (60 tests)
- [x] Paper's data construction: scope, 10-round player filter, leave-one-out hole difficulty,
      transitions
- [x] Descriptives: Table 1 and Figure 1 replicated next to the paper's values
- [x] Fitting software: R `lme4::glmer` in `%%R` cells, tested on the full men's sample
- [x] Replication model (paper's Equation 1) with AIC/BIC selection, men and women separately
- [x] Extension: player-round random effect (day form vs momentum)
- [x] Bias and power simulation that includes the random effects
- [x] Sensitivity grid (transition sets, field-average definition, match events, field size,
      extreme rounds, 20+ rounds, flat cards restored)
- [x] Poster figures and text

## Key design decisions

- **The order of play is unknown.** There is no starting-hole column. The primary sample uses
  the 16 hole-to-hole pairs per round that are consecutive under any 1st/10th-tee start, the
  same concern the paper raised about holes 1, 9, 10 and 18.
- **Hole difficulty is leave-one-out.** With college field sizes, including a player's own score
  in their difficulty covariate is not harmless; the paper's version is kept for a sensitivity
  check.
- **Dropped is always explained.** Every raw round has a `status` in
  `data/clean/d3_round_audit.parquet`.
