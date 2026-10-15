# Poster text: The Hand Stays Cold? Momentum Beyond Skill in College Golf

Numbers come from `cold_hand_poster.ipynb`. Figure and table names match the files in `poster/figures/`.

---

## Introduction
*(figure: `intro_timeline`)*

- **The hot hand:** does success make more success likely? Gilovich, Vallone & Tversky (1985) said no and called it a cognitive illusion.
- **The debate reopened:** Miller & Sanjurjo (2018) showed the original test was biased *against* finding streaks.
- **Golf is a clean test:** no defender, no opponent adjusting, and every player in the field faces the same holes on the same day.
- **Earlier golf studies disagree:** professionals show hot *and* cold hands (Livingston 2012; Arkes 2016). On the PGA Tour, Elmore & Urbaczewski (2018) found **no hot hand but a significant cold hand**.
- **Our question:** does that asymmetry hold below the professional level? Beyond **skill** and **the kind of day a player is having**, does a good or bad hole carry over to the next one?

## Data
*(figures: `fig1_player_averages`, `fig2_consistency`, `fig3_par_types`; table: `table1_data`, optionally `table2_par_types`)*

- **Hole-by-hole scores from Clippd** for NCAA Division III men's golf, 2023-24 to 2025-26.
- **Cleaning:** a tested pipeline (60 checks) removes duplicated, copied and fabricated scorecards, nine-hole totals spread across holes, and wrong course pars. **98.4%** of men's stroke-play rounds pass; rounds are kept or dropped whole.
- **Final sample:** **3,401 players** with 10+ rounds, from **290 schools**: **87,937 rounds** and **1,582,866 holes**.
- **These golfers average +8.1 per round.** That's far from the Tour (about even par) and far better than a typical weekend golfer (Fig. 1).
- **Better players are more consistent:** Pearson r = 0.59 between scoring average and round-to-round spread (Fig. 2). So volatility, not just skill, has to be controlled for.
- **Compared with the PGA Tour, D3 men make about half the birdies and twice the bogeys** on every par type (Table 2).

## Methods
*(equations: `eq1_strokes_gained`, `eq2_z_score`, `eq3_momentum`; figure: `fig5_shuffle`)*

1. **Strokes gained (Eq. 1).** Each hole is compared with the average of *everyone else* who played it on that course that day (leave-one-out). This removes hole difficulty, weather and pin positions.
2. **Skill and volatility.** For each player and par type (3, 4, 5): skill = mean strokes gained, volatility = its standard deviation. Both are taken from the player's *other* rounds.
3. **z-score (Eq. 2).** How far this hole was from what this player usually does on this type of hole, in the player's own standard deviations.
4. **Back-to-back holes.** Each hole is paired with the next one in the same nine (no tee-time data, so 9→10 is excluded).
5. **The shuffle (Eq. 3, Fig. 5).** The holes in each nine are put in random order, 200 times. The shuffle keeps the player and the day but breaks the order. **Momentum = real order − shuffled order.**
6. **Uncertainty.** 95% confidence intervals come from resampling whole players 1,000 times.

## Analysis & Results
*(figures: `fig6_association`, `fig7_cold_hand`; tables: `table3_results`, optionally `table4_robustness`)*

- **Good holes follow good holes:** after a blow-up hole (z ≤ −2) the next hole averages z = −0.095; after a great hole (z ≥ 2), +0.072 (Fig. 6, red).
- **Most of that is the day, not the previous hole:** with the hole order shuffled, the same comparison gives −0.077 and +0.089 (Fig. 6, grey).
- **Cold hand:** beyond skill and day form, a blow-up hole makes the next hole **0.018 SD worse** (95% CI −0.027 to −0.009; p = 0.005), about 0.015 strokes (Fig. 7).
- **No hot hand:** after a great hole there is no boost. If anything, a small letdown (−0.016 SD, 95% CI −0.031 to −0.001).
- **Holes in between** show no meaningful effect.
- **Robust:** the cold-hand estimate is negative in every season and subset, with its interval excluding zero in 5 of 7. It is not detectable among national-championship programs (Table 4).

## Conclusion

- **Most of what looks like momentum on a scorecard is skill and day form.** Players have good and bad *days*, not good and bad streaks of holes.
- **Beyond both, a blow-up hole still drags down the next one, and a great hole gives nothing extra:** a **cold hand without a hot hand**.
- **The same asymmetry appears on the PGA Tour** (Elmore & Urbaczewski 2018), so it holds from the Tour down to Division III.
- **The effect is small, about 0.015 strokes per blow-up hole,** but consistent: in golf, bad holes linger and good holes don't.
- **For players and coaches:** the hole *after* a disaster is where focus matters most.

## Future work

- **Shot-by-shot data (Clippd):** is the stroke lost after a blow-up off the tee, on the approach or on the green? Strokes gained by shot category (Broadie 2012) would show where the cold hand lives.
- **Tee times and starting holes:** the real order of play would allow all 17 transitions and rule out short weather bursts.
- **Hot day vs hot hand:** does a strong start *cause* a good day, or does a good day cause the strong start?
- **Other levels:** women's golf, Divisions I and II, and recreational golfers (handicap-app data).
- **Coaching:** test whether a reset routine after a bad hole shortens the cold hand.

## Sources & Acknowledgements

**Data.** Thank you to **Clippd** for generously providing the hole-by-hole NCAA Division III data that made this project possible.

**Acknowledgements.** Advised by Professor Ron Yurko, Carnegie Mellon Sports Analytics Center. Thanks to Carnegie Mellon Athletics.

1. Elmore, R., & Urbaczewski, A. (2018). Hot and cold hands on the PGA Tour: Do they exist? SSRN 2764498.
2. Gilovich, T., Vallone, R., & Tversky, A. (1985). The hot hand in basketball: On the misperception of random sequences. *Cognitive Psychology*, 17(3), 295–314.
3. Miller, J. B., & Sanjurjo, A. (2018). Surprised by the hot hand fallacy? A truth in the law of small numbers. *Econometrica*, 86(6), 2019–2047.
4. Livingston, J. A. (2012). The hot hand and the cold hand in professional golf. *Journal of Economic Behavior & Organization*, 81(1), 172–184.
5. Arkes, J. (2016). The hot hand vs. cold hand on the PGA Tour. *International Journal of Sport Finance*, 11(2).
6. Connolly, R. A., & Rendleman, R. J. (2008). Skill, luck, and streaky play on the PGA Tour. *Journal of the American Statistical Association*, 103(481), 74–88.
7. Bocskocsky, A., Ezekowitz, J., & Stein, C. (2014). The hot hand: A new approach to an old "fallacy." MIT Sloan Sports Analytics Conference.
8. Cotton, C., McIntyre, F., Price, J., et al. (2016). Correcting for bias in hot hand analysis: Analyzing performance streaks in youth golf.
9. Broadie, M. (2012). Assessing golfer performance on the PGA TOUR. *Interfaces*, 42(2), 146–165.
