getFillsForAllPreChains <- function(inputDF, orderCutOff)
{
  inputDF <- inputDF %>% mutate(pfx = str_replace_all(pfx,"[\\[\\]]",""))


  colName <- paste0("chain.",orderCutOff)

  inputDF <- inputDF %>%
    mutate(thisTag = paste0(network, sprintf("%.2f",FloorPrice)),
      tmp = paste0(pfx,ifelse(pfx=="","",":"), thisTag))

  inputDF[[colName]] <- inputDF$tmp
  result <- inputDF %>%  filter(ordinal==orderCutOff) %>%
    select(-tmp) %>% subscriptFillColumn(orderCutOff)
  fillData <- inputDF %>% filter(ordinal < orderCutOff) %>% rename(chain=tmp) %>%
    select(chain,Fill)

  prevColName <- colName
  for (i in (orderCutOff-1):0) {
      colName <- paste0("chain.",i)
      result[[colName]] <- result[[prevColName]] %>% removeLastTag()
      prevColName <- colName
      result <- left_join(result,fillData, by=setNames("chain",colName)) %>% subscriptFillColumn(i)
  }
  return(result)
}

getModelOrdinalZeroFillForCurrentTag <- function(df, modelDF)
{
  result <- left_join(df, modelDF %>% filter(ordinal==0) %>% select(network,FloorPrice, value) %>% rename(Fill.Model=value), by=c("network","FloorPrice"))
}


testPrefixFills <- function ()
{
  inputs <- loadAllInputs()
  integrateDate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    mutate(Fill = served/ impressions) %>% ungroup()
  res <- prefixFills(integrateDate,2)
  return(res)
}

subscriptFillColumn <- function(df, index)
{
  df[[paste0("Fill.",index)]] <- df$Fill
  df <- df %>% select(-Fill)
  return(df)
}

