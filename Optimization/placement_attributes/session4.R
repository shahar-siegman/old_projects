Session4 <- function() {
  df3 <- df %>% filter(placement_id==levels(df$placement_id)[[43]]) %>% preprocess() %>% UpchainNetworks() # [[22]]
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
  df$chain_networks <- gsub("[0-9.=]+","",df$chain)
  df <- df %>% mutate(upchain_networks = substr(chain_networks,1,as.numeric(as.character(ordinal))*2-1),
                      unique_upchain = uniqueChainTags(upchain_networks))
  return(df)
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
