# -----------------------------------------------------------

prepareSuperFactorTable <- function(df, superFactorName, otherFactorNames)
{
  refTable <- GroupByWithRollup(df, superFactorName)
  for (i in 1: length(otherFactorNames)) {
    currentFactorName <- otherFactorNames[i]
    df[[currentFactorName]] <- as.factor(df[[currentFactorName]])
    refTable <- rbind(refTable,GroupByWithRollup(df,superFactorName,currentFactorName))
  }
  return(refTable)
}


GroupByWithRollup <- function(df,factor1,factor2) {
  # creates a melted df with columns:
  # "factor1_name" - same for all rows
  # "factor1_level" - specifies level
  # "factor2_name" - specify factor 2 name
  # "factor2_level" - specify factor2 level
  # "impressions", "served" - sum
  # a value of "_" in factor2_name and factor2_level corresponds to sum over factor1

  if (missing(factor2) || is.na(factor2))
  {
    factor1Summary <- df %>% group_by_(factor1) %>% summarise(served=sum(served),impressions=sum(impressions)) %>% ungroup()
    res <- data.frame(
      factor1_name = factor1,
      factor1_level = factor1Summary[[factor1]],
      factor2_name = "_",
      factor2_level = "_",
      served = factor1Summary$served,
      impressions = factor1Summary$impressions
    )
  }
  else
  {
    factor1_2Summary <- df %>% group_by_(factor1,factor2) %>% summarise(served=sum(served),impressions=sum(impressions)) %>% ungroup()
    res <- data.frame(
      factor1_name = factor1,
      factor1_level = factor1_2Summary[[factor1]],
      factor2_name = factor2,
      factor2_level = factor1_2Summary[[factor2]],
      served = factor1_2Summary$served,
      impressions = factor1_2Summary$impressions
    )
  }
  return(res)
}

retrieve.ref.t <- function(refT, factor1Level,factor2Name,factor2Level) {
  if (is.na(factor1Level)) {
    # factor1 not specified - collect the performance of factor2 for all different levels of factor1
    row <- refT %>%
      filter(factor2_name == factor2Name,
             factor2_level == factor2Level) %>%
      group_by() %>% summarise(served=sum(served), impressions = sum(impressions))
  }
  else
  {
    row <- refT %>% filter(factor1_level == factor1Level,
                           factor2_name == factor2Name,
                         factor2_level == factor2Level)
  }
  return(row)
}

retrieve.generic <- function (df, case) {
  cols <- names(case)
  cond <- df[[cols[1]]]==case[[1]]
  if (length(case)>=2)
    for (i in 2: length(case)) {
      cond <- cond & df[[cols[i]]]==case[[i]]
    }
  rows <- df[cond,]
  return (rows)
}

PservedAndXi <- function(refTable,factor1Level, selfServed = 0 , selfImps = 0) {
  row <- retrieve.ref.t(refTable, factor1Level, "_","_")
  total <- refTable %>% filter(factor2_name=="_",factor2_level=="_" )
  fill <- (row$served - selfServed) / (sum(total$impressions) - selfImps)
  return(fill)
}

PXi <- function(refTable,factor1Level, selfImps = 0) {
  row <- retrieve.ref.t(refTable, factor1Level, "_","_")
  total <- refTable %>% filter(factor2_name=="_",factor2_level=="_" )
  pxi <- (row$impressions - selfImps) / (sum(total$impressions) - selfImps)
  return(pxi)
}



Pxj <- function(refTable, factorJName, factorJLevel, selfImps = 0)
{
  # all cases where factor is at specified level
  rowSet1 <- retrieve.generic(refTable, list(factor2_name=factorJName, factor2_level=factorJLevel))
  rowSet2 <- retrieve.generic(refTable, list(factor2_name=factorJName))
  pxj <- (sum(rowSet1$impressions) - selfImps) / (sum(rowSet2$impressions) - selfImps)
  return(pxj)
}

Pxj_served <- function(refTable, factorJName, factorJLevel, selfServed = 0) {
  rowSet1 <- retrieve.generic(refTable, list(factor2_name=factorJName, factor2_level=factorJLevel))
  rowSet2 <- retrieve.generic(refTable, list(factor2_name=factorJName))
  pxjServed <- (sum(rowSet1$served) - selfServed) / (sum(rowSet2$served) - selfServed)
  return(pxjServed)
}


Pxj_xi <- function(refTable, factorILevel,factorJName,factorJLevel, selfImps = 0) {
  row1 <- retrieve.ref.t(refTable, factorILevel, factorJName, factorJLevel)
  row2 <- retrieve.ref.t(refTable, factorILevel, "_","_")
  if (row1$impressions - selfImps == 0)
    XjGivenXi <- Pxj(refTable, factorJName,factorJLevel)
  else
    XjGivenXi <- (row1$impressions - selfImps)  / (row2$impressions - selfImps)

  return(XjGivenXi)
}

Pxj_served.xi <- function(refTable, factorILevel,factorJName,factorJLevel, selfServed = 0) {
  row1 <- retrieve.ref.t(refTable, factorILevel, factorJName, factorJLevel)
  row2 <- retrieve.ref.t(refTable, factorILevel, "_","_")
  if (row1$served - selfServed == 0) {
    XjGivenServedAndXi <- Pxj_served(refTable, factorJName,factorJLevel, selfServed)
  }
  else
  {
    XjGivenServedAndXi <- (row1$served - selfServed)  / (row2$served - selfServed)
  }
  return(XjGivenServedAndXi)
}


ClassifySingleCaseLeaveOneOut <- function(refTable, df, case) {
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