
ClassifySingleCaseLeaveOneOut <- function(refTable, df, case) {
  # produces a probability of success estimate for a a single case
  # accepts a refTable prepared by prepareSuperFactorTable
  # factors is a named vector
  # the names are the factor names, the values are the levels
  superFactorName <- refTable %>% filter(factor2_name=="_", factor2_level=="_") %>%
    `[[`("factor1_name") %>% `[`(1)
  superFactorLevel <- case[[superFactorName]]
  otherFactorNames <- names(case) %>% setdiff(superFactorName)
  otherFactorLevels <- case[otherFactorNames]

  rows <- retrieve.generic(df, case)
  selfImps = 0; selfServed = 0
  if (nrow(rows)>0) {
    selfImps <- sum(rows$impressions, na.rm=T)
    selfServed <- sum(rows$served, na.rm=T)
  }

  pServedXj <- numeric(length(otherFactorNames))
  pXjXi <- numeric(length(otherFactorNames))
  for (i in 1: length(otherFactorNames)) {
    currentFactorName <- otherFactorNames[i]
    currentFactorLevel <-otherFactorLevels[[i]]
    refRow <- retrieve.ref.t(refTable, superFactorLevel, currentFactorName, currentFactorLevel)
    pServedXj[i] <- Pxj_served.xi(refTable, superFactorLevel,currentFactorName,currentFactorLevel, selfServed)
    pXjXi[i] <- Pxj_xi(refTable, superFactorLevel,currentFactorName,currentFactorLevel, selfImps)
  }

  pServedXi <- PservedAndXi(refTable, superFactorLevel, selfServed, selfImps)
  pxi <- PXi(refTable,superFactorLevel,selfImps)

  pServedAndCase <- pServedXi * prod(pServedXj)
  pCase <- pxi * prod(pXjXi)
  p <- pServedAndCase/pCase
  return (c("prediction" =p, "served" = selfServed, "impressions" = selfImps))
}

existingCases <- function(df, factors) {
  args <- list()
  args[[1]] <- df
  args[2:(length(factors)+1)] <- factors
  existingCaseDf <- do.call(select_, args) %>% unique()
  return(existingCaseDf)
}


LeaveOneOutTest <- function(df,factors) {
  # uses the first factor in "factors" argument as the super-factor.
  # extract the list of cases from df and classifies them, ignoring each case's own data in its classification
  # returns the original df (unused columns removed) with a "prediction" column which contains the fill rate prediction
  existing <- existingCases(df,factors)
  nExisting <- nrow(existing)
  refTable <- prepareSuperFactorTable(df, factors[1], factors[2:length(factors)])
  result <- existing
  result$prediction <- 0
  result$served <- 0
  result$impressions <- 0
  for (i in 1:nExisting) {
    currentCase <- as.list(existing[i,])
    singleRes <- ClassifySingleCaseLeaveOneOut(refTable,df, currentCase)
    result[[i, "prediction"]] <- singleRes["prediction"]
    result[[i, "served"]] <- singleRes["served"]
    result[[i, "impressions"]] <- singleRes["impressions"]
  }
  result$fill = result$served/result$impressions
  result$super = factors[1]
  return(result)
}

LeaveOneOutFullTest <- function(df, factors)
{
  # loops calls to LeaveOneOutTest, each call with a different factor as the super-factor
  # returns a single DF, concatenated outputs of LeaveOneOutTest, with the super-factor listed in the "super" column

  nFactors <- length(factors)
  k <- LeaveOneOutTest(df, factors)
  for (i in 2: nFactors) {
    superFactor <- factors[i]
    otherFactors <- factors[(1:nFactors) !=i]
    kn <- LeaveOneOutTest(df, c(superFactor, otherFactors))
    k <- rbind(k,kn)
  }
  return(k)
}

Classify <- function(df, cases)
{
  # AODE classification of the specified cases using 'df' as the training data
  # infer the columns to use as attributes from the column names of 'cases'
  # 'cases' is expected to be a data frame, the columns names match columns in 'df',
  # the values are sets of values for which we want a fill prediction



}