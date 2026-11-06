# MA416 Project 1: Group-designed omnibus permutation test
# H0: Shooting rate and offensive rebounding are independent within every era.
# Ha: They are associated within at least one era.
# Test statistic: T = sum of the four squared within-era correlations.

cohort = read.csv("Data/big_men_analysis_2024.csv",
                  stringsAsFactors = FALSE)
totals = read.csv("Data/Player Totals.csv",
                  stringsAsFactors = FALSE)

era_names = c("era_1", "era_2", "era_3", "era_4")
era_counts = table(factor(cohort$assigned_era, levels = era_names))

stopifnot(
  nrow(cohort) == 1118,
  !anyDuplicated(cohort$player_id),
  all(as.integer(era_counts) == c(247, 229, 278, 364))
)

# Keep NBA player-seasons in the report's time window.
totals = subset(totals, lg == "NBA" & season >= 1981 & season <= 2024)

# Use the combined season total for players who changed teams.
combined = grepl("^[0-9]+TM$|^TOT$", totals$team)
totals = totals[order(combined, decreasing = TRUE), ]
totals = totals[!duplicated(totals[c("player_id", "season")]), ]

big_positions = c("C", "PF", "C-PF", "PF-C", "C/PF", "PF/C")
totals = totals[totals$pos %in% big_positions, ]

totals$season_era = cut(
  totals$season,
  breaks = c(1980, 1991, 2002, 2013, 2024),
  labels = era_names,
  right = TRUE
)

# Use only each player's seasons from their assigned era.
player_index = match(totals$player_id, cohort$player_id)
keep = !is.na(player_index) &
       totals$season_era == cohort$assigned_era[player_index]
totals = totals[keep, ]

player_sums = aggregate(
  cbind(fga, x3pa, orb, mp) ~ player_id,
  data = totals,
  FUN = sum
)

# Match the totals to the cohort and check that shot counts agree with Q1.
player_index = match(cohort$player_id, player_sums$player_id)
stopifnot(!anyNA(player_index))
player_sums = player_sums[player_index, ]

stopifnot(
  all(player_sums$fga == cohort$fga),
  all(player_sums$x3pa == cohort$x3pa),
  all(player_sums$mp > 0)
)

shooting_rate = player_sums$x3pa / player_sums$fga
rebounds_per_36 = 36 * player_sums$orb / player_sums$mp
era = factor(cohort$assigned_era, levels = era_names)

x_split = split(shooting_rate, era)
y_split = split(rebounds_per_36, era)

# Calculate the observed statistic from the original player pairs.
r_obs = sapply(era_names, function(j) {
  cor(x_split[[j]], y_split[[j]])
})
T_obs = sum(r_obs^2)

# Shuffle rebounding separately within each era on every replicate.
set.seed(123)
B = 100000
T_perm = numeric(B)

for (b in seq_len(B)) {
  r_perm = sapply(era_names, function(j) {
    cor(x_split[[j]], sample(y_split[[j]]))
  })
  T_perm[b] = sum(r_perm^2)
}

n_extreme = sum(T_perm >= T_obs)
p_omnibus = (1 + n_extreme) / (B + 1)

print(era_counts)
print(r_obs, digits = 8)
print(c(T_obs = T_obs, shuffles = B,
        n_extreme = n_extreme, p_value = p_omnibus), digits = 8)