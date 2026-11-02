Question 3: Three-Point Attempt Rate and Offensive Rebounding

Research Question
Within each era, is a big man's three-point attempt rate correlated with how many offensive rebounds the player grabs?
Question 1 showed that big men's three-point attempt rates rose sharply across eras. This question asks whether that shift came with a trade-off within the role. If big men who move to the perimeter grab fewer offensive rebounds, the two skills move in opposite directions. Testing every era shows whether the trade-off has always existed or developed as the role changed.
This is a claim about association (a correlation), not about a mean or any other measure of central tendency.

Variables
We used the same 1,145-player cohort and the same assigned-era seasons as Question 1. For each player, we summed raw totals across those seasons:
Three-point attempt rate = Total three-point attempts / Total field-goal attempts
Offensive rebounds per 36 minutes = 36 × Total offensive rebounds / Total minutes played
We verified that the rebuilt field-goal and three-point attempt totals matched the Question 1 dataset exactly for all 1,145 players.
We tested each era separately. Pooling all eras would mix two different things: differences between players at the same time and league-wide changes between eras, such as rule changes, pace, and team rebounding strategy. The pooled correlation across all 1,145 players was −0.60, weaker than the correlations within eras 3 and 4, because the era 1 players are bunched near a rate of zero and dilute the pattern.

Why Nonparametric Methods
The classical test for a correlation, T = r√(n − 2) / √(1 − r²) with n − 2 degrees of freedom, and the Fisher confidence interval both assume the two variables are bivariate normal. Shapiro–Wilk tests rejected normality of three-point attempt rate in every era:
Era 1: W = 0.39690; p < 2.2 × 10⁻¹⁶
Era 2: W = 0.50723; p < 2.2 × 10⁻¹⁶
Era 3: W = 0.65583; p < 2.2 × 10⁻¹⁶
Era 4: W = 0.93811; p = 1.107 × 10⁻¹¹
Offensive rebounds per 36 minutes failed normality in eras 1, 2, and 4 (p = 8.2 × 10⁻⁹, 1.2 × 10⁻⁴, and 2.3 × 10⁻⁶). It passed in era 3 (W = 0.99444; p = 0.406), but bivariate normality requires both variables to be normal, so the classical methods are unjustified in every era.
We therefore used two nonparametric methods that do not assume any distribution for the data: a bootstrap confidence interval and a Monte Carlo permutation test. We report the classical results only as a comparison.

Hypotheses
Let ρⱼ be the population correlation between three-point attempt rate and offensive rebounds per 36 minutes among big men in era j, for j = 1, 2, 3, 4.
Null hypothesis: In era j, there is no linear association between the two variables.
H0: ρⱼ = 0
Alternative hypothesis: In era j, the two variables are correlated.
H1: ρⱼ ≠ 0
Overall significance level: α = 0.05

Adjusting for Four Tests
Running one test per era means running four tests. If each test used α = 0.05, the familywise error rate, the chance of at least one false rejection across the four eras, would be:
FWER = 1 − (1 − α)ᵈ = 1 − (0.95)⁴ = 0.1855
To hold the familywise error rate at 0.05, we solved the same formula for the per-test level:
α_fw = 1 − (1 − 0.05)^(1/4) = 0.01274
Each era was therefore tested at α_fw = 0.01274, which corresponds to a 98.73% confidence interval.
Decision rule: Reject H0 for era j if its 98.73% bootstrap confidence interval does not contain 0, or equivalently if its permutation p-value is below 0.01274.

Assumption Checks
Independence
Each player contributed one pair of values to one era. As in Question 1, players shared teams, coaches, and league conditions, so this did not prove independence. Teammates compete for the same rebounds, so this limitation matters here. Both the bootstrap and the permutation test treat players as independent.
Representative Sample
The bootstrap treats each era's sample as a model of that era's population. Each era had between 229 and 391 players. The conclusions apply only to this cohort definition.
Paired Resampling
A player's three-point attempt rate and offensive rebounding rate belong together. The bootstrap resampled whole players, so each player's pair stayed intact. The permutation test deliberately broke the pairs, which is what "no association" would look like.
Shape of the Relationship
The correlation measures linear association only, so we inspected a scatterplot with a smoothed trend line for each era. In eras 2, 3, and 4, the trend fell steadily as three-point attempt rate increased. In era 4, it fell from about 3.9 offensive rebounds per 36 minutes at a rate near 0 to about 1.0 at a rate near 0.85.
Era 1 was different. The median player took only 0.6% of their shots from three, and only 8 of 247 players exceeded 10%. The trend dropped among players near zero and then flattened among those few higher-volume shooters. The era 1 correlation therefore rests mostly on small differences among players who rarely shot threes and should be interpreted cautiously.

Method 1: Bootstrap Confidence Interval
Sample correlation within each era:
r = Σ(xᵢ − x̄)(yᵢ − ȳ) / √[Σ(xᵢ − x̄)² · Σ(yᵢ − ȳ)²]
Bootstrap procedure within each era (10,000 resamples, seed 123):

1. Draw nⱼ players from that era's sample with replacement.
2. Compute the correlation for the resampled players.
3. Repeat 10,000 times.

The 98.73% percentile interval runs from the 0.637th percentile to the 99.363rd percentile of the 10,000 bootstrap correlations. We also report the unadjusted 95% interval for reference.

Method 2: Monte Carlo Permutation Test
If H0 is true, a player's rebounding has nothing to do with their three-point rate, so any rebounding value could have been paired with any three-point rate. Within each era (10,000 shuffles, seed 123):

1. Randomly shuffle the offensive rebounding values among the players.
2. Compute the correlation for the shuffled pairs.
3. Repeat 10,000 times.

The two-sided p-value counts how often a shuffled correlation was at least as far from 0 as the observed one, using the plus-one rule:
p = (number of shuffles with |r*| ≥ |r| + 1) / (10,000 + 1)

Results
Bootstrap confidence intervals:
Era 1 (1981–1991): 247 players; r = −0.172; bootstrap SE = 0.063; 95% CI (−0.298, −0.059); 98.73% CI (−0.326, −0.029)
Era 2 (1992–2002): 229 players; r = −0.498; bootstrap SE = 0.061; 95% CI (−0.604, −0.367); 98.73% CI (−0.627, −0.332)
Era 3 (2003–2013): 278 players; r = −0.630; bootstrap SE = 0.035; 95% CI (−0.693, −0.556); 98.73% CI (−0.708, −0.533)
Era 4 (2014–2025): 391 players; r = −0.711; bootstrap SE = 0.022; 95% CI (−0.753, −0.668); 98.73% CI (−0.764, −0.655)
Every 98.73% interval was entirely below 0.

Permutation test:
Era 1: 111 of 10,000 shuffles were at least as extreme; p = 0.0112
Era 2: 0 of 10,000 shuffles; p = 0.0001
Era 3: 0 of 10,000 shuffles; p = 0.0001
Era 4: 0 of 10,000 shuffles; p = 0.0001
For eras 2, 3, and 4, the most extreme shuffled correlation was about ±0.25 at most, far from the observed values. A p-value of 0.0001 is the smallest that 10,000 shuffles can show; the true p-values are smaller. Every p-value was below 0.01274.

Decision: We rejected H0 in all four eras. In every era, big men with higher three-point attempt rates tended to grab fewer offensive rebounds per 36 minutes.
The era 1 result was the weakest. Its permutation p-value of 0.0112 was only slightly below the adjusted level of 0.01274, and its bootstrap interval stopped just short of 0 at −0.029.

Comparison with the Classical Methods
For reference, the classical T test and Fisher interval (at the same 98.73% level) gave:
Era 1: T = −2.73, df = 245, p = 0.0067; Fisher CI (−0.321, −0.014)
Era 2: T = −8.64, df = 227, p = 1.0 × 10⁻¹⁵; Fisher CI (−0.612, −0.363)
Era 3: T = −13.46, df = 276, p = 4.2 × 10⁻³²; Fisher CI (−0.712, −0.530)
Era 4: T = −19.96, df = 389, p = 1.5 × 10⁻⁶¹; Fisher CI (−0.768, −0.643)
The classical methods reached the same decisions, and their intervals were close to the bootstrap intervals. Because normality failed, however, their p-values cannot be trusted at face value. In era 1, the classical p-value (0.0067) was noticeably smaller than the permutation p-value (0.0112), which suggests the classical test overstated the evidence when its assumptions failed.

How Much Rebounding Does Three-Point Rate Explain?
A significant correlation does not by itself mean three-point attempt rate is a useful predictor of offensive rebounding. The share of the variation in offensive rebounding explained by three-point attempt rate is r²:
Era 1: r² = 0.030 (3%)
Era 2: r² = 0.248 (25%)
Era 3: r² = 0.396 (40%)
Era 4: r² = 0.506 (51%)
In era 1, the association was statistically detectable but explained almost none of the differences in rebounding. By era 4, three-point attempt rate alone accounted for about half of the variation in offensive rebounding among big men.

Interpretation
The trade-off between three-point shooting and offensive rebounding has existed among big men since the 1980s, but it was weak when almost no big men shot threes. As three-point attempts spread through the position, the trade-off became strong. By era 4, a correlation of about −0.71 means that knowing how often a big man shoots threes says a great deal about how much that player crashes the offensive glass. The era 1 interval did not overlap the era 3 or era 4 intervals, which suggests the relationship is stronger now than in the 1980s. Adjacent eras overlapped slightly, so the data do not show that each era is stronger than the one immediately before it. Comparing intervals is a visual check, not a formal test of whether two correlations differ.
This pattern is consistent with big men splitting into two roles: perimeter-spacing bigs and traditional interior bigs.
These results do not establish causation. A player standing at the three-point line is farther from the basket when a shot misses, but coaching decisions, team rebounding strategy, and player body type could produce the same pattern. The independence limitation also applies: both methods treat players as independent even though teammates share rebounding opportunities, so the true uncertainty may be somewhat larger than reported. The era 1 result should be read cautiously because so few players in that era shot threes at all and its evidence was close to the adjusted cutoff.
Our conclusions apply to qualifying big men assigned to one era who attempted at least 100 field goals within that era.
