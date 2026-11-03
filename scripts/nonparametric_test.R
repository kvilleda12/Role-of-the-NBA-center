# Question 3: Nonparametric test (bootstrap)
# Claim: within each era, big men's three-point attempt rate and
# offensive rebounds per 36 minutes are correlated (we expect negatively:
# big men who shoot more threes rebound less on the offensive glass).
#
# This is a claim about association (the correlation rho), not about a
# mean or any other measure of central tendency.
#
# For each era j = 1, 2, 3, 4:
# H0: rho_j = 0
# H1: rho_j != 0
#
# Method: nonparametric bootstrap percentile confidence interval for the
# correlation in each era (class L10 code). Four tests are run, so each
# uses the per-test level that holds the familywise error rate at alpha
# (L06: FWER = 1 - (1 - alpha_fw)^d, solved for alpha_fw). Reject H0 for
# an era if its adjusted interval excludes 0.
#
# For comparison, the L13 classical T test and Fisher interval for rho are
# also computed. They assume bivariate normality, which fails here, so they
# are reported for reference only.

# Set the significance level
alpha = 0.05

# Load the prepared player-level data from 01_clean_data.R
big_men_analysis = read.csv(
  "Data/big_men_analysis.csv",
  stringsAsFactors = FALSE
)


# Rebuild each player's assigned-era seasons from the raw totals
# (same filters as 01_clean_data.R) so that offensive rebounds and
# minutes can be summed over exactly the seasons used in Question 1

player_totals = read.csv(
  "Data/Player Totals.csv",
  stringsAsFactors = FALSE
)

# Keep NBA records from 1981 through 2025
nba_totals = subset(
  player_totals,
  lg == "NBA" & season >= 1981 & season <= 2025
)

# Keep combined-team records for traded players and drop their stints
nba_totals$combined_team = grepl("^[0-9]+TM$|^TOT$", nba_totals$team)

nba_totals = nba_totals[
  order(nba_totals$combined_team, decreasing = TRUE),
]

nba_totals = nba_totals[
  !duplicated(paste(nba_totals$player_id, nba_totals$season)),
]

# Keep big-man seasons
big_positions = c("C", "PF", "C-PF", "PF-C", "C/PF", "PF/C")

big_totals = nba_totals[nba_totals$pos %in% big_positions, ]

# Label each season with its era
big_totals$season_era = as.character(cut(
  big_totals$season,
  breaks = c(1980, 1991, 2002, 2013, 2025),
  labels = c("era_1", "era_2", "era_3", "era_4"),
  right = TRUE
))

# Keep only seasons inside each analysed player's assigned era
assigned_era = setNames(
  big_men_analysis$assigned_era,
  big_men_analysis$player_id
)

big_totals = big_totals[
  big_totals$player_id %in% big_men_analysis$player_id &
    big_totals$season_era == assigned_era[big_totals$player_id],
]

# Sum attempts, offensive rebounds, and minutes for each player
player_sums = aggregate(
  cbind(fga, x3pa, orb, mp) ~ player_id,
  data = big_totals,
  FUN = sum
)

nonpar_data = merge(big_men_analysis, player_sums,
                    by = "player_id", suffixes = c("", "_check"))

# Verify the rebuild matches Question 1 exactly
stopifnot(
  nrow(nonpar_data) == nrow(big_men_analysis),
  all(nonpar_data$fga == nonpar_data$fga_check),
  all(nonpar_data$x3pa == nonpar_data$x3pa_check)
)

# Offensive rebounds per 36 minutes
nonpar_data$orb_per_36 = 36 * nonpar_data$orb / nonpar_data$mp

nonpar_data$assigned_era = factor(
  nonpar_data$assigned_era,
  levels = c("era_1", "era_2", "era_3", "era_4")
)


# Split each variable by era (values first, groups second)
x_split = split(nonpar_data$three_point_attempt_rate, nonpar_data$assigned_era)
y_split = split(nonpar_data$orb_per_36, nonpar_data$assigned_era)

nj = sapply(x_split, length)
g = length(x_split)

nj

# Correlation from its definition (L13, no cor())
corr_def = function(X, Y){
  sum((X - mean(X))*(Y - mean(Y))) /
    sqrt(sum((X - mean(X))^2)*sum((Y - mean(Y))^2))
}

# Familywise error rate if each of the d = 4 tests used alpha (L06)
d = g
1 - (1 - alpha)^d

# Per-test level that holds the familywise error rate at alpha
alpha_fw = 1 - (1 - alpha)^(1/d)

alpha_fw
1 - alpha_fw   # confidence level of each adjusted interval


# Why a nonparametric test: the usual t test for a correlation assumes
# the two variables are (bivariate) normal, so check each one formally.
# Shapiro-Francia statistic by hand (L04): small values mean non-normal
sfstat = function(S){
  X = sort(S)
  n = length(X)
  Xc = X - mean(X)
  SST = sum(Xc^2)
  mk = qnorm((1:n - 3/8)/(n+1/4))
  mk_length = as.numeric(sqrt(t(mk)%*%mk))
  ak = mk/mk_length
  tau = (sum(ak*Xc))^2
  tau/SST
}

# Monte-Carlo p-value (left tail, plus-one rule). The statistic does not
# depend on the mean or SD, so standard normal samples of the same size
# give its null distribution.
set.seed(123)
nmc_sf = 10000
normality = t(sapply(names(x_split), function(era_name) {
  n = nj[era_name]
  mcsf = c()
  for(k in 1:nmc_sf){
    mcsf = c(mcsf, sfstat(rnorm(n, 0, 1)))
  }
  sf_rate = sfstat(x_split[[era_name]])
  sf_orb = sfstat(y_split[[era_name]])
  c(SF_rate = sf_rate, pval_rate = (sum(mcsf <= sf_rate) + 1)/(nmc_sf + 1),
    SF_orb = sf_orb, pval_orb = (sum(mcsf <= sf_orb) + 1)/(nmc_sf + 1))
}))

normality

# Reject normality if the p-value is at or below alpha
normality[, c("pval_rate", "pval_orb")] <= alpha

# Players with no three-point attempts pile up at zero
sapply(x_split, function(v) sum(v == 0))

# Few players took more than 10% of their shots from three in early eras
sapply(x_split, function(v) sum(v > 0.10))


# Sample correlation in each era
rj = sapply(names(x_split), function(era_name) {
  corr_def(x_split[[era_name]], y_split[[era_name]])
})

rj

# Share of the variation in offensive rebounding explained (L13)
rj^2


# Bootstrap in each era: resample player INDICES with replacement so
# each player's (x, y) pair stays together, then recompute the correlation
nboot = 10000
boot_cor = list()

for (era_name in names(x_split)) {
  X = x_split[[era_name]]
  Y = y_split[[era_name]]
  n = length(X)

  set.seed(123)
  mycor = c()
  myindex = seq(1, n, 1)
  for(k in 1:nboot){
    sboot = sample(myindex, n, replace=T)
    Xboot = X[sboot]
    Yboot = Y[sboot]
    mycor = c(mycor, corr_def(Xboot, Yboot))
  }

  boot_cor[[era_name]] = mycor
}

# Bootstrap standard error in each era
se_boot = sapply(boot_cor, sd)

# Unadjusted 95% percentile intervals
ci_95 = t(sapply(boot_cor, quantile, probs = c(alpha/2, 1-alpha/2)))

# FWER-adjusted intervals used for the decisions
ci_fw = t(sapply(boot_cor, quantile,
                 probs = c(alpha_fw/2, 1-alpha_fw/2)))

results = data.frame(
  n = nj,
  r = rj,
  r_squared = rj^2,
  se_boot = se_boot,
  ci95_lower = ci_95[, 1],
  ci95_upper = ci_95[, 2],
  fw_lower = ci_fw[, 1],
  fw_upper = ci_fw[, 2]
)

results

# Decision in each era: reject H0 if 0 is outside the adjusted interval
results$reject_H0 = results$fw_lower > 0 | results$fw_upper < 0

results[, c("r", "fw_lower", "fw_upper", "reject_H0")]


# Comparison: L13 classical T test and Fisher interval for rho in each era
# (both assume bivariate normality, which the Shapiro-Francia tests rejected)
classical = t(sapply(names(x_split), function(era_name) {
  X = x_split[[era_name]]
  Y = y_split[[era_name]]
  n = length(Y)

  # Correlation from its definition (no cor())
  rxy = corr_def(X, Y)

  # Classical approach
  SE_r = sqrt((1 - rxy^2)/(n-2))
  tstat = (rxy - 0)/SE_r
  pval = 2*pt(abs(tstat), n-2, lower.tail=F)

  # Fisher approach at the FWER-adjusted level
  zetar = atanh(rxy)
  zcrit = qnorm(alpha_fw/2, lower.tail=F)
  ci_fr = tanh(c(zetar - zcrit/sqrt(n-3), zetar + zcrit/sqrt(n-3)))

  c(tstat = tstat, df = n - 2, pval = pval,
    fisher_lower = ci_fr[1], fisher_upper = ci_fr[2])
}))

classical

# Reject at the adjusted level if the p-value is below alpha_fw
classical[, "pval"] < alpha_fw


# Monte-Carlo permutation test in each era: if H0 is true, any player's
# rebounding could have been paired with any player's three-point rate,
# so shuffle Y, recompute the correlation, and see how often a correlation
# at least as far from 0 as the observed one appears by chance
nmc = 10000
perm_cor = list()

for (era_name in names(x_split)) {
  X = x_split[[era_name]]
  Y = y_split[[era_name]]

  set.seed(123)
  mcrs = c()
  for(k in 1:nmc){
    mcY = sample(Y)
    mcrs = c(mcrs, corr_def(X, mcY))
  }

  perm_cor[[era_name]] = mcrs
}

# Two-sided Monte-Carlo p-value with the plus-one rule
perm_count = sapply(names(perm_cor), function(era_name) {
  sum(abs(perm_cor[[era_name]]) >= abs(rj[era_name]))
})
perm_pval = (perm_count + 1)/(nmc + 1)

data.frame(r = rj,
           most_extreme_shuffled = sapply(perm_cor, function(v) max(abs(v))),
           count = perm_count,
           pval = perm_pval,
           reject_H0 = perm_pval < alpha_fw)


# For comparison: the correlation with all eras pooled together
corr_def(nonpar_data$three_point_attempt_rate, nonpar_data$orb_per_36)


# ======================= Figures for the report ===============================
# Each figure is written to reports/figures/

era_titles = c(era_1 = "Era 1 (1981–1991)", era_2 = "Era 2 (1992–2002)",
               era_3 = "Era 3 (2003–2013)", era_4 = "Era 4 (2014–2025)")

dir.create("reports/figures", showWarnings = FALSE)


# Figure 3.1: scatterplot in each era with a trend line built by hand:
# the mean of each variable within 0.05-wide bands of three-point rate
# (bands with at least 5 players)
png("reports/figures/q3_fig1_scatter.png", width = 2000, height = 1500,
    res = 250)
par(mfrow = c(2, 2), mar = c(4.2, 4.5, 2.2, 1), las = 1)

for (era_name in names(x_split)) {
  plot(x_split[[era_name]], y_split[[era_name]],
       pch = 16, cex = 0.7, col = adjustcolor("steelblue", 0.5),
       xlim = c(0, 0.9), ylim = c(0, 7),
       main = era_titles[era_name],
       xlab = "Three-point attempt rate",
       ylab = "Offensive rebounds per 36")
  band = floor(x_split[[era_name]]/0.05)
  band_n = tapply(x_split[[era_name]], band, length)
  band_x = tapply(x_split[[era_name]], band, mean)[band_n >= 5]
  band_y = tapply(y_split[[era_name]], band, mean)[band_n >= 5]
  lines(band_x, band_y, type = "b", pch = 15, col = "red", lwd = 2)
  legend("topright", legend = sprintf("r = %.3f", rj[era_name]), bty = "n")
}

dev.off()


# Figure 3.2: bootstrap distribution of r in each era, with the adjusted
# percentile interval (dashed) and the Fisher interval (dotted)
png("reports/figures/q3_fig2_bootstrap.png", width = 2000, height = 1500,
    res = 250)
par(mfrow = c(2, 2), mar = c(4.2, 4.5, 2.2, 1), las = 1)

for (era_name in names(boot_cor)) {
  hist(boot_cor[[era_name]], breaks = 40, col = "lightblue",
       main = era_titles[era_name],
       xlab = "Bootstrap correlation r*", ylab = "Frequency")
  abline(v = ci_fw[era_name, ], col = "red", lwd = 2, lty = 2)
  abline(v = classical[era_name, c("fisher_lower", "fisher_upper")],
         col = "darkgreen", lwd = 2, lty = 3)
}

dev.off()


# Figure 3.3: permutation distribution of r under H0 in each era, with the
# observed correlation
png("reports/figures/q3_fig3_permutation.png", width = 2000, height = 1500,
    res = 250)
par(mfrow = c(2, 2), mar = c(4.2, 4.5, 2.2, 1), las = 1)

for (era_name in names(perm_cor)) {
  counts = hist(perm_cor[[era_name]], breaks = 40, plot = FALSE)$counts
  hist(perm_cor[[era_name]], breaks = 40, col = "lightpink",
       xlim = range(c(perm_cor[[era_name]], rj[era_name])) + c(-0.05, 0.05),
       ylim = c(0, 1.3*max(counts)),
       main = era_titles[era_name],
       xlab = "Correlation after shuffling", ylab = "Frequency")
  abline(v = rj[era_name], col = "blue", lwd = 2.5)
  legend("topright", legend = sprintf("Observed r = %.3f", rj[era_name]),
         col = "blue", lwd = 2.5, bty = "n", cex = 0.9)
}

dev.off()


# Figure 3.4: correlation and FWER-adjusted bootstrap interval for each era
png("reports/figures/q3_fig4_by_era.png", width = 2000, height = 1200,
    res = 250)
par(mar = c(4.2, 4.5, 2.2, 1), las = 1)

plot(1:g, rj, pch = 19, cex = 1.3, col = "steelblue", xaxt = "n",
     xlim = c(0.5, g + 0.5), ylim = c(-1, 0.1),
     main = "Correlation by Era with Adjusted Bootstrap Intervals",
     xlab = "Era", ylab = "Correlation r")
axis(1, at = 1:g, labels = era_titles)
arrows(1:g, ci_fw[, 1], 1:g, ci_fw[, 2],
       angle = 90, code = 3, length = 0.08, lwd = 2, col = "steelblue")
abline(h = 0, lty = 2, col = "gray50")
text(1:g, ci_fw[, 1] - 0.07, sprintf("r² = %.2f", rj^2), col = "darkred")

dev.off()
