# Question 3: Three-Point Attempt Rate and Offensive Rebounding (Bootstrap)

Updated for season-ending years 1981–2024; season 2025 is excluded.

Run `scripts/01_clean_data.R` followed by `scripts/nonparametric_test.R` from the repository root.

## Research question and data

Among era_4 big men (2014–2024), is three-point attempt rate associated with offensive rebounds per 36 minutes?
The analysis uses 1118 players, including 364 in era_4.
NBA C/PF-only player-seasons are deduplicated using combined-team records. Each player is assigned to the era with the most qualifying seasons; ties go to the earlier era. Only assigned-era seasons contribute to the totals. Players need at least 100 field-goal attempts within that era.
Three-point attempt rate = summed three-point attempts / summed field-goal attempts.
Offensive rebounds per 36 = 36 × summed offensive rebounds / summed minutes.
The script verifies that rebuilt attempt totals match the original era-analysis dataset for every player.

## Hypotheses and procedure

H0: rho = 0. H1: rho != 0. Alpha = 0.05.
The Lecture 10 procedure resamples paired player indices with replacement 10,000 times using set.seed(123), then takes the 2.5th and 97.5th percentiles of the bootstrap correlations. Reject H0 when the interval excludes zero. No additional correction is applied.

## Assumptions and diagnostics

Era_4 three-point attempt rate: Shapiro-Wilk W = 0.935952, p = 2.07407e-11.
Era_4 offensive rebounds per 36: Shapiro-Wilk W = 0.975907, p = 9.2423e-06.
Players with zero three-point attempts in era_4: 13.
Both marginal normality tests reject normality. These tests alone do not establish or refute every condition needed for correlation inference. The bootstrap retains each player’s paired measurements and does not impose a normal population model.
One observation per player prevents duplicate subjects, but shared teams, coaches, and league conditions can limit independence. Correlation summarizes linear association and does not show causation. Cohort filtering limits generalization.

## Era_4 results

Sample correlation: -0.723192.
Mean bootstrap correlation: -0.723321.
Bootstrap standard error: 0.0219958.
95% percentile bootstrap confidence interval: (-0.764378, -0.678405).
The interval is entirely below zero: reject H0. Among the eligible modern big men, higher three-point attempt rates are associated with lower offensive rebounding rates.

## Supplementary results by era

Era boundaries: era_1 1981–1991, era_2 1992–2002, era_3 2003–2013, era_4 2014–2024.

| Era | Players | Correlation | 95% bootstrap CI |
|---|---:|---:|---|
| era_1 | 247 | -0.172042 | (-0.29759, -0.058691) |
| era_2 | 229 | -0.49751 | (-0.604443, -0.366594) |
| era_3 | 278 | -0.629569 | (-0.693362, -0.555662) |
| era_4 | 364 | -0.723192 | (-0.764378, -0.678405) |

The supplementary intervals describe each era separately; their differences do not constitute a formal test that correlations differ across eras.
