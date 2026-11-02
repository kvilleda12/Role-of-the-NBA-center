# Question 1: Prepare big-man three-point attempt rates

# Load original player-season data
player_stats = read.csv(
  "Data/Player_stats_36min.csv",
  stringsAsFactors = FALSE
)

# Inspect the dataset
dim(player_stats)
names(player_stats)
head(player_stats)


# Keep NBA records from 1981 through 2025
nba_seasons = subset(
  player_stats,
  lg == "NBA" & season >= 1981 & season <= 2025
)

# Check the filtered data
dim(nba_seasons)
range(nba_seasons$season)
table(nba_seasons$lg)

# Identify combined-team records, such as 2TM or 3TM
nba_seasons$combined_team = grepl(
  "^[0-9]+TM$|^TOT$",
  nba_seasons$team
)

# Count combined and individual-team records
table(nba_seasons$combined_team)

# Show which combined-team labels occur
table(
  nba_seasons$team[nba_seasons$combined_team]
)

# Identify each unique player-season combination
player_season_key = paste(
  nba_seasons$player_id,
  nba_seasons$season,
  sep = "_"
)

# Count all records and combined records for each player-season
record_counts = table(player_season_key)

combined_counts = tapply(
  nba_seasons$combined_team,
  player_season_key,
  sum
)

# Find multi-record player-seasons without exactly one combined record
problem_keys = names(record_counts)[
  record_counts > 1 &
    combined_counts[names(record_counts)] != 1
]

length(problem_keys)

# Put combined-team records first
nba_seasons = nba_seasons[
  order(nba_seasons$combined_team, decreasing = TRUE),
]

# Rebuild the player-season identifiers after sorting
player_season_key = paste(
  nba_seasons$player_id,
  nba_seasons$season,
  sep = "_"
)

# Keep the first record for each player-season
nba_player_seasons = nba_seasons[
  !duplicated(player_season_key),
]

# Check the result
dim(nba_player_seasons)

anyDuplicated(
  nba_player_seasons[c("player_id", "season")]
)

# Define eligible big-man position labels
big_positions = c(
  "C", "PF", "C-PF", "PF-C", "C/PF", "PF/C"
)

# Keep qualifying big-man player-seasons
big_men_seasons = nba_player_seasons[
  nba_player_seasons$pos %in% big_positions,
]

# Check the retained records and position labels
dim(big_men_seasons)

table(big_men_seasons$pos)

length(unique(big_men_seasons$player_id))


# Define the era labels in chronological order
era_labels = c("era_1", "era_2", "era_3", "era_4")

# Assign each player-season to an era
big_men_seasons$season_era = cut(
  big_men_seasons$season,
  breaks = c(1980, 1991, 2002, 2013, 2025),
  labels = era_labels,
  right = TRUE
)

# Check player-season counts in each era
table(big_men_seasons$season_era, useNA = "ifany")


# Count each player's qualifying seasons in each era
player_era_counts = table(
  big_men_seasons$player_id,
  big_men_seasons$season_era
)

# Identify the column with the largest count for each player
assigned_era_column = max.col(
  player_era_counts,
  ties.method = "first"
)

# Convert column numbers to era labels
assigned_era = era_labels[assigned_era_column]

# Label each assignment with its player ID
names(assigned_era) = rownames(player_era_counts)

# Inspect the season counts and player assignments
head(player_era_counts)
table(assigned_era)

# Match each player's assigned era to their season records
big_men_seasons$assigned_era = unname(
  assigned_era[big_men_seasons$player_id]
)

# Retain only seasons within the player's assigned era
assigned_era_seasons = big_men_seasons[
  as.character(big_men_seasons$season_era) ==
    big_men_seasons$assigned_era,
]

# Check that all players received an assignment
sum(is.na(big_men_seasons$assigned_era))

# Check retained player-season records and distinct players
dim(assigned_era_seasons)

length(unique(assigned_era_seasons$player_id))


# Load raw player-season totals
player_totals = read.csv(
  "Data/Player Totals.csv",
  stringsAsFactors = FALSE
)

# Inspect the available columns and a few records
names(player_totals)

head(
  player_totals[
    , c("player_id", "season", "lg", "team", "fga", "x3pa")
  ]
)


# Define the columns identifying a player-team-season record
match_columns = c("player_id", "season", "lg", "team")

# Select identifiers and raw attempt totals
attempt_totals = player_totals[
  , c(match_columns, "fga", "x3pa")
]

# Check that source identifiers are unique
anyDuplicated(attempt_totals[match_columns])

# Attach totals to our selected player-season records
big_men_with_totals = merge(
  assigned_era_seasons,
  attempt_totals,
  by = match_columns,
  all.x = TRUE
)

# Check row counts and missing totals
nrow(assigned_era_seasons)
nrow(big_men_with_totals)

colSums(
  is.na(big_men_with_totals[, c("fga", "x3pa")])
)


# Check that attempt counts are valid
stopifnot(
  all(big_men_with_totals$fga >= 0),
  all(big_men_with_totals$x3pa >= 0),
  all(big_men_with_totals$x3pa <= big_men_with_totals$fga)
)

# Sum attempts across each player's seasons within their assigned era
big_men_player_totals = aggregate(
  cbind(fga, x3pa) ~ player_id + assigned_era,
  data = big_men_with_totals,
  FUN = sum
)

# Retain players with at least 100 field-goal attempts
big_men_analysis = subset(
  big_men_player_totals,
  fga >= 100
)

# Calculate each player's three-point attempt rate
big_men_analysis$three_point_attempt_rate =
  big_men_analysis$x3pa / big_men_analysis$fga

# Check player counts before and after the cutoff
table(big_men_player_totals$assigned_era)
table(big_men_analysis$assigned_era)

# Confirm one observation per player and inspect the rates
anyDuplicated(big_men_analysis$player_id)
head(big_men_analysis)

# Set era order for subsequent tables, plots, and tests
big_men_analysis$assigned_era = factor(
  big_men_analysis$assigned_era,
  levels = era_labels
)

# Check that every rate is present and between 0 and 1
stopifnot(
  !anyNA(big_men_analysis$three_point_attempt_rate),
  all(big_men_analysis$three_point_attempt_rate >= 0),
  all(big_men_analysis$three_point_attempt_rate <= 1)
)

# Save the prepared data for the analysis script
write.csv(
  big_men_analysis,
  "Data/big_men_analysis.csv",
  row.names = FALSE
)