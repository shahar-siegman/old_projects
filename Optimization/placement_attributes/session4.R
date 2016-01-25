Session4 <- function() {
  df3 <- df %>% filter(placement_id==levels(df$placement_id)[[43]]) %>% preprocess() %>% upchainNetworks()
  df4 <- df %>% filter(placement_id==levels(df$placement_id)[[48]])
  u4 <- df4 %>% preprocess() %>% upchainNetworks() %>%
    group_by(network,upchain_networks,floor_price) %>%
    summarise(start_date=min(as.Date(date_joined)),end_date=max(as.Date(date_joined)),
              ordinal=mean(as.numeric(as.character(ordinal))),served=sum(served),impressions=sum(impressions),
              tags=paste(unique(tag_name),collapse=",")) %>%
    mutate(fill = served/impressions)
  ggplot(u4) + geom_path(aes(x=floor_price, y=fill,color=upchain_networks,group=upchain_networks)) + facet_wrap(~network)
}

UpchainNetworks <- function(df) {
  df <- df %>% mutate(chain_networks = gsub("[0-9.=]+","",df$chain),
                upchain_networks = substr(chain_networks,1,as.numeric(as.character(ordinal))*2-1),
                unique_upchain = uniqueChainTags(upchain_networks)) %>%
    return()
}

uniqueChainTags <- function(chain) {
  chain %>% strsplit(":") %>% lapply(sort) %>% lapply(unique) %>% lapply(function(x) paste(x, collapse=":")) %>% unlist() %>% return()
}

jointServedAndOneFactor <- function(df,factor) {
  df %>% group_by_(factor) %>%
    summarise(served=sum(served),impressions=sum(impressions)) %>%
    ungroup() %>%
    mutate(p_y.x = served/sum(impressions)) %>%
    return()
}

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
  row <- refT %>% filter(factor1_level == factor1Level,
                       factor2_name == factor2Name,
                       factor2_level == factor2Level)
  return(row)
}

retrieve.generic <- function (df, case) {
  cols <- names(case)
  cond <- df[[cols[1]]]==case[1]
  for (i in 2: length(case)) {
    cond <- cond & df[[cols[i]]]==case[i]
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


Pxj_served.xi <- function(refTable, factorILevel,factorJName,factorJLevel, selfServed = 0) {
  row1 <- retrieve.ref.t(refTable, factorILevel, factorJName, factorJLevel)
  row2 <- retrieve.ref.t(refTable, factorILevel, "_","_")
  XjGivenServedAndXi <- (row1$served - selfServed)  / (row2$served - selfServed)

  return(XjGivenServedAndXi)
}

Pxj_xi <- function(refTable, factorILevel,factorJName,factorJLevel, selfImps = 0) {
  row1 <- retrieve.ref.t(refTable, factorILevel, factorJName, factorJLevel)
  row2 <- retrieve.ref.t(refTable, factorILevel, "_","_")
  XjGivenXi <- (row1$impressions - selfImps)  / (row2$impressions - selfImps)
  return(XjGivenXi)
}

ClassifySingleCaseLeaveOneOut <- function(refTable, df, case) {
  # accepts a refTable prepared by prepareSuperFactorTable
  # factors is a named vector
  # the names are the factor names, the values are the levels
  superFactorName <- refTable %>% filter(factor2_name=="_", factor2_level=="_") %>%
    `[[`("factor1_name") %>% `[`(1)
  superFactorLevel <- case[superFactorName]
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
    currentFactorLevel <-otherFactorLevels[i]
    refRow <- retrieve.ref.t(refTable, superFactorLevel, currentFactorName, currentFactorLevel)
    pServedXj[i] <- Pxj_served.xi(refTable, superFactorLevel,currentFactorName,currentFactorLevel, selfServed)
    pXjXi[i] <- Pxj_xi(refTable, superFactorLevel,currentFactorName,currentFactorLevel, selfImps)
  }

  pServedXi <- Pserved_xi(refTable, superFactorLevel, selfServed, selfImps)
  pxi <- PXi(refTable,superFactorLevel,selfImps)

  pServedAndCase <- pServedXi * prod(pServedXj)
  pCase <- pxi * prod(pXjXi)
  p <- pServedAndCase/pCase
  return (p)
}

#  --------------------------------------------------*/
factorProbsConditionalOnServedAndSuperFactor <- function(df,superFactor,factors) {
  bySuperFactor <- df %>% group_by_(superFactor) %>% summarise(served_i=sum(served), impressions_i=sum(impressions)) %>% ungroup()
  factors <- setdiff(factors, superFactor)
  nf= length(factors)
  result <- list()
  for (i in 1: nf) {
    currentFactor = factors[i]

    byFactor <- df %>%
      group_by_(superFactor, currentFactor) %>%
      summarise(served=sum(served),impressions=sum(impressions)) %>%
      ungroup() %>%
      mutate(factor_name=currentFactor) %>%  # adds a column with the current factor name
      rename_("factor_level"=currentFactor) # renames the column CurrentFactor created in the group_by_ to "factor_name"

    bySuperAndCurrentFactors <- left_join(bySuperFactor,byFactor, by=superFactor)
    bySuperAndCurrentFactors$xj_y.xi <- bySuperAndCurrentFactors$served / bySuperAndCurrentFactors$served_i
    result[[currentFactor]] <- bySuperAndCurrentFactors
  }
  return(result)
}

classifyAllCombinationsSingleSuperFactor <- function(df,superFactor,factors) {
  all <- data.frame(impressions= sum(df$impressions), served = sum(df$served))

  freqMap <- factorProbsConditionalOnServedAndSuperFactor (df,superFactor,factors)

  factors <- setdiff(factors, superFactor)
  nFactors <- length(factors)

  superFactorLevels <- levels(as.factor(df[[superFactor]]))
  nSuperLevels <- length(superFactorLevels)

  myLevels <- list()
  for (j in 1:nFactors) {
    currentFactor <- factors[j]
    currentFactorLevels <- unique(factorFreqMap$factor_level)
    myLevels[[currentFactor]] <- data.frame()

    for (k in 1:length(currentFactorLevels)) {
      rows <- factorFreqMap %>% filter(factor_level ==currentFactorLevels[k])
      rows$xj_y.xi <- rows$served / rows$served_i
    }
  }

#     for (i in 1:nSuperLevels) {
#     superLevel <- superFactorLevels[i]
#     r1 <- freqMap
#     y.xi <- freqMap[[1]] %>% filter_(superFactor==superLevel) %>% `[[`("served") /
#       all$impressions
#
#       }
#     }
#   }

}


twoFactorFill <- function(df,factor1,factor2) {
  df %>% group_by_(factor1,factor2) %>%
    summarise(served=sum(served),impressions=sum(impressions)) %>%
    mutate(fill=served/impressions) %>%
    return()
}

fillClassifier <- function(df,superFactor,factors) {
  factors <- setdiff(factors, superFactor)
  nf <- length(factors)
  jointProbs <- list()
  singleProbs <- list()
  for (i in 1: nf) {
    currentFactor <- factors[i]
    jointProbs[[currentFactor]] <- twoFactorFill(df,superFactor,currentFactor)
    singleProbs[[currentFactor]] <- oneFactorFill(df,currentFactor)
  }
  return(list(jointProbs=jointProbs,singleProbs=singleProbs))
}
