# prepareSuperFactorTable (calls GroupByWithRollup) - summarise the data by
# attributes pairs, one designated as primary, the others cycle as secondary
# the primary is referred to as the super factor
source("../../libraries.R")

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


# retrieve.ref.t: another low-level functionality. fetch the statistics stored
# in a single row in the super-factor table
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

# case is a map attribute_name -> value
# can be used on any df instead of "filter" as a cleaner programmatic alternative
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

# the probability extraction functions in all below functions, imps is number of
# cases and served is number of successes in the binary target attribute
# since the target attribute is binary, P(y) always implies P(y=success)

# PservedAndXi = P(y, xi) = count(y,xi=v) / count(*)
PservedAndXi <- function(refTable,factor1Level, selfServed = 0 , selfImps = 0) {
  row <- retrieve.ref.t(refTable, factor1Level, "_","_")
  total <- refTable %>% filter(factor2_name=="_",factor2_level=="_" )
  fill <- (row$served - selfServed) / (sum(total$impressions) - selfImps)
  return(fill)
}

# PXi = P(xi=v) = count(xi=v) / count(*)
PXi <- function(refTable,factor1Level, selfImps = 0) {
  row <- retrieve.ref.t(refTable, factor1Level, "_","_")
  total <- refTable %>% filter(factor2_name=="_",factor2_level=="_" )
  pxi <- (row$impressions - selfImps) / (sum(total$impressions) - selfImps)
  return(pxi)
}

# PXj = same as P(Xi) implemented for secondary attributes
Pxj <- function(refTable, factorJName, factorJLevel, selfImps = 0)
{
  # all cases where factor is at specified level
  rowSet1 <- retrieve.generic(refTable, list(factor2_name=factorJName, factor2_level=factorJLevel))
  rowSet2 <- retrieve.generic(refTable, list(factor2_name=factorJName))
  pxj <- (sum(rowSet1$impressions) - selfImps) / (sum(rowSet2$impressions) - selfImps)
  return(pxj)
}

# Pxj_served = P(Xj=v | served) = count(Xj = v , served) / count(served)
Pxj_served <- function(refTable, factorJName, factorJLevel, selfServed = 0) {
  rowSet1 <- retrieve.generic(refTable, list(factor2_name=factorJName, factor2_level=factorJLevel))
  rowSet2 <- retrieve.generic(refTable, list(factor2_name=factorJName))
  pxjServed <- (sum(rowSet1$served) - selfServed) / (sum(rowSet2$served) - selfServed)
  return(pxjServed)
}

# Pxj_xi = P(Xj=v | Xi =t) = count(Xj = v, Xi = t) / count(Xi=t)
Pxj_xi <- function(refTable, factorILevel,factorJName,factorJLevel, selfImps = 0, pWeightParam=NULL) {
  row1 <- retrieve.ref.t(refTable, factorILevel, factorJName, factorJLevel)
  row2 <- retrieve.ref.t(refTable, factorILevel, "_","_")
  prior <- Pxj(refTable, factorJName,factorJLevel)
  pWeight <- getPriorWeight(pWeightParam)
  XjGivenXi <- (row1$impressions - selfImps + prior*pWeight)  / (row2$impressions - selfImps + pWeight)
  return(XjGivenXi)
}

# Pxj_served.xi = P(xj=v | xi=t, served) = count(xj=v, xi=t, served) / count(xi=t,served)
Pxj_served.xi <- function(refTable, factorILevel,factorJName,factorJLevel, selfServed = 0, pWeightParam=NULL) {
  row1 <- retrieve.ref.t(refTable, factorILevel, factorJName, factorJLevel)
  row2 <- retrieve.ref.t(refTable, factorILevel, "_","_")
  prior <- Pxj_served(refTable, factorJName,factorJLevel, selfServed)
  pWeight <- getPriorWeight(pWeightParam)
  XjGivenServedAndXi <- (row1$served - selfServed + prior*pWeight)  / (row2$served - selfServed + pWeight)
  return(XjGivenServedAndXi)
}

getPriorWeight <- function(pWeightParam) {
  return (10)
}
