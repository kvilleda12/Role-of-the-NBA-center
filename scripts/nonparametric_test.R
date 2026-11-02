# Question 3: Nonparametric test (bootstrap)
# Claim: among modern big men (era 4), three-point attempt rate and
# offensive rebounds per 36 minutes are correlated (we expect negatively:
# big men who shoot more threes rebound less on the offensive glass).
#
# This is a claim about association (the correlation rho), not about a
# mean or any other measure of central tendency.
#
# H0: rho = 0
# H1: rho != 0
#
# Method: nonparametric bootstrap percentile confidence interval for the
# correlation (class L10 code). Reject H0 if the interval excludes 0.

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


# Primary test group: era 4 (2014-2025)
era4 = subset(nonpar_data, assigned_era == "era_4")

x = era4$three_point_attempt_rate
y = era4$orb_per_36
n = length(x)

n
summary(x)
summary(y)


# Why a nonparametric test: the usual t test for a correlation assumes
# the two variables are (bivariate) normal, so check each one formally
shapiro.test(x)
shapiro.test(y)

# Players with no three-point attempts pile up at zero
sum(x == 0)


# Graphs: histograms of both variables and a scatterplot
old_par = par(mfrow = c(1, 2))

hist(x, breaks = seq(0, 1, by = 0.05), col = "lightblue",
     main = "Era 4: three-point attempt rate",
     xlab = "Three-point attempt rate", ylab = "Number of players")

hist(y, breaks = 20, col = "lightblue",
     main = "Era 4: offensive rebounds per 36",
     xlab = "Offensive rebounds per 36 minutes", ylab = "Number of players")

par(old_par)

plot(x, y, pch = 19, col = rgb(0, 0, 1, 0.4),
     main = "Era 4: three-point attempt rate vs offensive rebounding",
     xlab = "Three-point attempt rate",
     ylab = "Offensive rebounds per 36 minutes")

# Smooth trend line to judge the shape of the relationship
lines(lowess(x, y), col = "red", lwd = 2)


# Sample correlation
rxy = cor(x, y)

rxy


# Bootstrap: resample player INDICES with replacement so each player's
# (x, y) pair stays together, then recompute the correlation
set.seed(123)
nboot = 10000
mycor = c()
myindex = seq(1, n, 1)
for(k in 1:nboot){
  sboot = sample(myindex, n, replace=T)
  Xboot = x[sboot]
  Yboot = y[sboot]
  mycor = c(mycor, cor(Xboot, Yboot))
}

# Bootstrap distribution summary
mean(mycor)
sd(mycor)

# 95% percentile confidence interval for rho
cirxy = quantile(mycor, c(alpha/2, 1-alpha/2))

cirxy

# Decision: reject H0 if 0 is outside the interval
cirxy[1] > 0 | cirxy[2] < 0

hist(mycor, breaks = 40, col = "lightblue",
     main = "Bootstrap distribution of the correlation (era 4)",
     xlab = "Bootstrap correlation", ylab = "Frequency")
abline(v = cirxy, col = "red", lwd = 2, lty = 2)
abline(v = rxy, col = "blue", lwd = 2)


# Supplementary: the same bootstrap interval within every era, to see
# whether the trade-off is specific to the modern era
era_boot = sapply(split(nonpar_data, nonpar_data$assigned_era), function(d) {
  xe = d$three_point_attempt_rate
  ye = d$orb_per_36
  ne = nrow(d)
  set.seed(123)
  mycor_e = c()
  for(k in 1:nboot){
    sboot = sample(seq(1, ne, 1), ne, replace=T)
    mycor_e = c(mycor_e, cor(xe[sboot], ye[sboot]))
  }
  c(n = ne, r = cor(xe, ye), quantile(mycor_e, c(alpha/2, 1-alpha/2)))
})

t(era_boot)

# Boxplot of offensive rebounding by era for context
boxplot(orb_per_36 ~ assigned_era, data = nonpar_data, col = "lightblue",
        main = "Offensive rebounds per 36 minutes by era",
        xlab = "Era", ylab = "Offensive rebounds per 36 minutes")
