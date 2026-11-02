# Lecture 11 Mann-Whitney: six era pairs, unadjusted p-values.
# X is each player's three-point attempt rate within their assigned era.
nba = read.csv("Data/big_men_analysis.csv")
nba$Era = factor(nba$assigned_era, levels = c("era_1", "era_2", "era_3", "era_4"))
X = nba$three_point_attempt_rate

dsplit = split(X, nba$Era)

mannwhitney = function(S1, S2){

  L = list(s1 = S1, s2 = S2)
  nj = sapply(L, length)

  Sall = unlist(L)
  idx = rep(names(L), times=nj)

  Rall = rank(Sall)
  Rj = split(Rall, idx)

  Tj = sapply(Rj, sum)
  Uj = Tj - nj*(nj+1)/2

  MWstat = min(Uj)

  pval = wilcox.test(S1, S2)$p.value

  c(MWstat = MWstat, pval = pval)
}

# Pair order: 1 vs 2, 1 vs 3, 1 vs 4, 2 vs 3, 2 vs 4, 3 vs 4.
mannwhitney(dsplit[[1]], dsplit[[2]])
mannwhitney(dsplit[[1]], dsplit[[3]])
mannwhitney(dsplit[[1]], dsplit[[4]])

mannwhitney(dsplit[[2]], dsplit[[3]])
mannwhitney(dsplit[[2]], dsplit[[4]])

mannwhitney(dsplit[[3]], dsplit[[4]])
