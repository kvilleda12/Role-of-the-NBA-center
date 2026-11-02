# Question 1: Compare big-man three-point attempt rates across eras

# Load the prepared player-level data
big_men_analysis = read.csv(
  "Data/big_men_analysis.csv",
  stringsAsFactors = FALSE
)

# Restore era as a categorical variable in chronological order
big_men_analysis$assigned_era = factor(
  big_men_analysis$assigned_era,
  levels = c("era_1", "era_2", "era_3", "era_4")
)

# Verify the imported data
dim(big_men_analysis)
table(big_men_analysis$assigned_era)
anyDuplicated(big_men_analysis$player_id)


# Separate player rates into four era groups
rates_by_era = split(
  big_men_analysis$three_point_attempt_rate,
  big_men_analysis$assigned_era
)

# Display four histograms in a 2-by-2 layout
old_par = par(mfrow = c(2, 2))

for (era_name in names(rates_by_era)) {
  hist(
    rates_by_era[[era_name]],
    breaks = seq(0, 1, by = 0.05),
    main = era_name,
    xlab = "Three-point attempt rate",
    ylab = "Number of players",
    col = "lightblue",
    xlim = c(0, 1)
  )
}

# Restore the previous plotting settings
par(old_par)


# Set the significance level
alpha = 0.05

# Formally test normality within each era
for (era_name in names(rates_by_era)) {
  cat("\nNormality test for", era_name, "\n")

  print(
    shapiro.test(rates_by_era[[era_name]])
  )
}


# Ordinary one-factor ANOVA
# Caution: normality was rejected in all four eras;
# equal population variances have not been established.

anova_model = aov(
  three_point_attempt_rate ~ assigned_era,
  data = big_men_analysis
)

# Display the ANOVA table
summary(anova_model)

# Mean three-point attempt rate in each era
sapply(rates_by_era, mean)

# Standard deviation within each era
sapply(rates_by_era, sd)


# Welch's ANOVA: allows unequal population variances
# Normality and independence assumptions still apply

# Group sizes, means, and variances
nj = sapply(rates_by_era, length)
xbarj = sapply(rates_by_era, mean)
s2j = sapply(rates_by_era, var)

g = length(rates_by_era)
vj = nj - 1

# Inverse-variance weights
wj = nj / s2j
W = sum(wj)

# Weighted grand mean
xbar_w = sum(wj * xbarj) / W

# Weighted between-group sum of squares and mean square
SSM_star = sum(wj * (xbarj - xbar_w)^2)
MSM_star = SSM_star / (g - 1)

# Adjustment for unequal variances
Lambda = sum((1 - wj / W)^2 / vj)

# Welch's F statistic
F_welch = MSM_star / (
  1 + 2 * (g - 2) * Lambda / (g^2 - 1)
)

# Degrees of freedom
df1 = g - 1
df2 = (g^2 - 1) / (3 * Lambda)

# Upper-tail p-value and critical value
p_welch = pf(F_welch, df1, df2, lower.tail = FALSE)
F_crit_welch = qf(alpha, df1, df2, lower.tail = FALSE)

# Display results
F_welch
df1
df2
F_crit_welch
p_welch

# Reject H0 when the p-value is below alpha
p_welch < alpha


# Rank-based comparison across the four eras
# Does not require normality; independence is still required
kruskal_result = kruskal.test(
  three_point_attempt_rate ~ assigned_era,
  data = big_men_analysis
)

kruskal_result