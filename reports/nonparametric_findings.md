# Question 3: Three-Point Attempt Rate and Offensive Rebounding (Bootstrap)

Code: `scripts/nonparametric_test.R` (run from the repository root after `scripts/01_clean_data.R`).

## Research Question

Among modern NBA big men (era 4, 2014–2025), is a player's three-point attempt rate correlated with how many offensive rebounds the player grabs?

Question 1 showed that big men's three-point attempt rates rose sharply across eras. This question asks whether that shift came with a trade-off inside the role. If big men who drift to the perimeter grab fewer offensive rebounds, the two skills move in opposite directions.

This is a claim about **association** (a correlation), not about a mean or any other measure of central tendency.

## Variables

We used the same 1,145-player cohort and the same assigned-era seasons as Question 1. For each player we summed raw totals across those seasons from `Player Totals.csv`:

Three-point attempt rate = Total three-point attempts / Total field-goal attempts

Offensive rebounds per 36 minutes = 36 × Total offensive rebounds / Total minutes played

The script checks that the rebuilt field-goal and three-point attempt totals match `big_men_analysis.csv` exactly for all 1,145 players.

The primary analysis uses the 391 era 4 players. We worked within one era because the league as a whole changed between eras. Pooling all eras could produce a correlation driven by era differences rather than by differences between players.

## Why a Nonparametric Bootstrap

The usual t test for a correlation assumes the two variables are bivariate normal. Shapiro–Wilk tests rejected normality for both variables in era 4:

Three-point attempt rate: W = 0.93811; p = 1.107 × 10⁻¹¹
Offensive rebounds per 36: W = 0.97453; p = 2.318 × 10⁻⁶

The three-point rate histogram also has a large spike near zero: 11 players attempted no threes, and many more attempted only a few. The bootstrap does not assume any distribution for the data. It treats the 391 players as a stand-in for the population and resamples from them to estimate how much the sample correlation would vary.

## Hypotheses

Let ρ be the population correlation between three-point attempt rate and offensive rebounds per 36 minutes among era 4 big men.

H0: ρ = 0 (no linear association)
H1: ρ ≠ 0

Significance level: 0.05

Decision rule: reject H0 if the 95% bootstrap confidence interval for ρ does not contain 0.

## Assumption Checks

**Independence.** Each player contributes one pair of values. As in Question 1, players shared teams, coaches, and league conditions, so this does not prove independence. Teammates compete for the same rebounds, so this limitation matters here. The bootstrap also assumes independence, because it resamples players as if each one were an independent draw.

**Representative sample.** The bootstrap treats the sample as a model of the population. With 391 players, the sample covers the range of era 4 big men well. The conclusions apply only to this cohort definition.

**Paired resampling.** A player's three-point rate and rebounding rate belong together. We resampled player indices, not the two variables separately, so each player's pair stays intact.

**Shape of the relationship.** The correlation measures linear association. The scatterplot with a lowess smoother falls steadily from about 3.9 offensive rebounds per 36 at a rate near 0 to about 1.0 at a rate near 0.85. The curve bends slightly, steeper at low rates, but never changes direction. The correlation is therefore a reasonable summary, although it slightly understates how fast rebounding falls among the lowest-volume shooters.

## Method

Sample correlation:

r = Σ (xᵢ − x̄)(yᵢ − ȳ) / √[ Σ (xᵢ − x̄)² · Σ (yᵢ − ȳ)² ]

Bootstrap procedure (B = 10,000, seed 123):

1. Draw 391 player indices from 1, …, 391 with replacement.
2. Compute the correlation r*ₖ for the resampled pairs.
3. Repeat B times, giving r*₁, …, r*_B.

95% percentile confidence interval:

( r*₍₀.₀₂₅₎ , r*₍₀.₉₇₅₎ )

where r*₍q₎ is the q-th quantile of the 10,000 bootstrap correlations.

## Results

n = 391
Sample correlation: r = −0.7114
Mean of bootstrap correlations: −0.7119
Bootstrap standard error: 0.0216

95% bootstrap confidence interval for ρ: (−0.7531, −0.6680)

**Decision.** The interval lies entirely below 0, so we reject H0. Among era 4 big men, three-point attempt rate and offensive rebounding are negatively correlated.

For comparison, the normal-theory t test gave t = −19.96 with df = 389 and p < 2.2 × 10⁻¹⁶. Its 95% interval was (−0.757, −0.659), close to the bootstrap interval. The two methods agree even though the normality assumption behind the t test failed.

## Supplementary: Every Era

We repeated the same bootstrap within each era. These results are descriptive context and were not part of the pre-stated test.

| Era | Players | r | 95% bootstrap CI |
|---|---|---|---|
| 1 (1981–1991) | 247 | −0.172 | (−0.298, −0.059) |
| 2 (1992–2002) | 229 | −0.498 | (−0.604, −0.367) |
| 3 (2003–2013) | 278 | −0.630 | (−0.693, −0.556) |
| 4 (2014–2025) | 391 | −0.711 | (−0.753, −0.668) |

Every interval lies below 0. The correlation becomes stronger in each later era. In era 1, almost no big men shot threes, so the rates were bunched near zero and the correlation was weak. By era 4, big men spread across a wide range of rates. Players at the high end rebounded much less than players at the low end. The boxplot of offensive rebounds by era shows a lower median and a much wider spread in era 4.

## Interpretation

In the modern era, big men who take more of their shots from three tend to grab fewer offensive rebounds. A correlation of about −0.71 is strong, and the bootstrap interval rules out values weaker than about −0.67. The trade-off has strengthened across the four eras. This is consistent with big men splitting into two roles: perimeter-spacing bigs and traditional interior bigs.

These results do not show causation. A player standing at the three-point line is physically farther from the basket when a shot misses, but coaching decisions, team rebounding strategy, and player body type could all produce the same pattern. The independence limitation also applies: the bootstrap treats players as independent even though teammates share rebounding opportunities, so the true uncertainty may be somewhat larger than the interval shows.

Our conclusions apply to qualifying big men assigned to era 4 who attempted at least 100 field goals within that era.
