options(digits = 15)

# Run from the repository root. Seasons are labeled by ending year.
# Rookie season means first recorded NBA season, before position/year filtering.
totals = read.csv("Data/Player Totals.csv", stringsAsFactors = FALSE)
totals = totals[totals$lg == "NBA", ]
stopifnot(!anyNA(totals$player_id), !anyNA(totals$season))

totals$combined = grepl("^[0-9]+TM$|^TOT$", totals$team)
keys = paste(totals$player_id, totals$season, sep = "_")
record_counts = table(keys)
combined_counts = tapply(totals$combined, keys, sum)
stopifnot(all(combined_counts[names(record_counts)[record_counts > 1]] == 1))
totals = totals[order(totals$combined, decreasing = TRUE), ]
totals = totals[!duplicated(totals[c("player_id", "season")]), ]

rookies = aggregate(season ~ player_id, data = totals, FUN = min)
rookies = rookies[rookies$season >= 1981 & rookies$season <= 2024, ]
rookies = rookies[order(rookies$player_id), ]
big_positions = c("C", "PF", "C-PF", "PF-C", "C/PF", "PF/C")
era_labels = c("era_1", "era_2", "era_3", "era_4")
eligible_rows = list()
exclusions = c(fourth_season_after_2024 = 0, missing_consecutive_season = 0,
               not_big_man_all_four_seasons = 0, missing_attempts = 0,
               invalid_attempts = 0)

for (i in seq_len(nrow(rookies))) {
  id = rookies$player_id[i]
  rookie = rookies$season[i]
  if (rookie + 3 > 2024) {
    exclusions["fourth_season_after_2024"] = exclusions["fourth_season_after_2024"] + 1
    next
  }
  rows = totals[totals$player_id == id & totals$season %in% (rookie + 0:3), ]
  rows = rows[order(rows$season), ]
  if (nrow(rows) != 4 || !all(rows$season == rookie + 0:3)) {
    exclusions["missing_consecutive_season"] = exclusions["missing_consecutive_season"] + 1
    next
  }
  # Require an explicitly eligible big-man position in every measurement season.
  if (!all(rows$pos %in% big_positions)) {
    exclusions["not_big_man_all_four_seasons"] = exclusions["not_big_man_all_four_seasons"] + 1
    next
  }
  if (anyNA(rows[c("fga", "x3pa")])) {
    exclusions["missing_attempts"] = exclusions["missing_attempts"] + 1
    next
  }
  if (!all(is.finite(rows$fga) & is.finite(rows$x3pa) &
           rows$fga > 0 & rows$x3pa >= 0 & rows$x3pa <= rows$fga)) {
    exclusions["invalid_attempts"] = exclusions["invalid_attempts"] + 1
    next
  }
  rates = rows$x3pa / rows$fga
  eligible_rows[[length(eligible_rows) + 1]] = data.frame(
    player_id = id, Player = rows$player[1],
    Era = as.character(cut(rookie, breaks = c(1980, 1991, 2002, 2013, 2024),
                           labels = era_labels, right = TRUE)),
    RookieSeason = rookie,
    Season1 = rates[1], Season2 = rates[2],
    Season3 = rates[3], Season4 = rates[4]
  )
}

eligible = do.call(rbind, eligible_rows)
eligible = eligible[order(eligible$player_id), ]
eligible_counts = table(factor(eligible$Era, levels = era_labels))
cat("Eligible players by era:\n")
print(eligible_counts)
cat("Exclusions among players whose first recorded NBA season is 1981-2024:\n")
print(exclusions)

target = c(13, 13, 12, 12)
if (any(eligible_counts < target)) {
  print(data.frame(Era = era_labels, Eligible = as.integer(eligible_counts), Target = target))
  stop("Insufficient eligible players for the planned sample; no players duplicated.")
}

set.seed(123)
selected = integer(0)
for (j in seq_along(era_labels)) {
  candidates = which(eligible$Era == era_labels[j])
  selected = c(selected, sample(candidates, target[j], replace = FALSE))
}
sampled = eligible[selected, ]
stopifnot(nrow(sampled) == 50, !anyDuplicated(sampled$player_id))
nba = sampled[c("Player", "Era", "RookieSeason", "Season1", "Season2", "Season3", "Season4")]
stopifnot(!anyNA(nba), all(as.matrix(nba[c("Season1", "Season2", "Season3", "Season4")]) >= 0),
          all(as.matrix(nba[c("Season1", "Season2", "Season3", "Season4")]) <= 1))
write.csv(nba, "NBA_RM.csv", row.names = FALSE)
cat("Final sample sizes:\n")
print(table(factor(nba$Era, levels = era_labels)))

# MA416 Lecture 9: the supplied manual RM-ANOVA procedure.
nba = read.csv("NBA_RM.csv")

T1 = nba$Season1
T2 = nba$Season2
T3 = nba$Season3
T4 = nba$Season4

X = cbind(T1, T2, T3, T4)

# Sample sizes and means
n = nrow(X)
g = ncol(X)

xbarj = colMeans(X)
xbari = rowMeans(X)
xbarbar = mean(X)

# Total variation
s2all = var(c(X))
SST = s2all*(n*g-1)

# Between-measurement variation
SSM = n*sum((xbarj-xbarbar)^2)

# Between-subject variation
SSS = g*sum((xbari-xbarbar)^2)

# Error variation
E = X - xbari -
    matrix(xbarj, n, g, byrow=TRUE) +
    xbarbar

SSE = sum(E^2)

# Verify decomposition
c(SST, SSM+SSS+SSE)
stopifnot(isTRUE(all.equal(SST, SSM+SSS+SSE)))

# Mean squares
MSM = SSM/(g-1)
MSE = SSE/((n-1)*(g-1))

# Test statistic
Fstat = MSM/MSE
Fstat

# P-value and critical value
alpha = 0.05

pval = pf(Fstat, g-1,
          (n-1)*(g-1),
          lower.tail=F)

Fcrit = qf(alpha, g-1,
           (n-1)*(g-1),
           lower.tail=F)

pval
Fcrit

cat("Sample means and standard deviations:\n")
print(data.frame(Season = paste0("Season", 1:4), Mean = xbarj,
                 SD = apply(X, 2, sd)), row.names = FALSE)
cat("Manual RM-ANOVA results (df = 3, 147):\n")
print(c(SST = SST, SSM = SSM, SSS = SSS, SSE = SSE,
        MSM = MSM, MSE = MSE, Fstat = Fstat, Fcrit = Fcrit, pval = pval))

shapiro.test(T1)
shapiro.test(T2)
shapiro.test(T3)
shapiro.test(T4)

dir.create("reports", showWarnings = FALSE)
pdf("reports/NBA_RM_histograms.pdf", width = 8, height = 8)
par(mfrow=c(2,2))

hist(T1, main="Season 1", xlab="3PA Rate")
hist(T2, main="Season 2", xlab="3PA Rate")
hist(T3, main="Season 3", xlab="3PA Rate")
hist(T4, main="Season 4", xlab="3PA Rate")
dev.off()

# MA416 Lecture 9: supplied uncorrected Mauchly procedure.
M = contr.poly(g)

Sc = t(M) %*% var(X) %*% M

p = g-1

W = det(Sc)/(sum(diag(Sc))/p)^p

Mo = -(n-1)*log(W)

nu = p*(p+1)/2-1

mauchly_pval = pchisq(Mo, nu,
                     lower.tail=F)

W
Mo
mauchly_pval

if (mauchly_pval < alpha) {
  cat("Sphericity is rejected. The ordinary RM-ANOVA p-value requires correction; no correction was applied.\n")
} else {
  cat("Sphericity is not rejected by the supplied Mauchly test.\n")
}
cat("Players are distinct, but shared teams and league conditions may limit independence.\n")
cat("Repeated observations belong to the same player and are expected to be dependent.\n")
cat("Rookie years are inferred from the first recorded NBA season in the source.\n")
