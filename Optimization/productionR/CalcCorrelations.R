source('../../libraries.R')

singleChainToDF <- function(inputRow,tabulatedModels)
{
  # assumes only ordinal-2 rows in input
  chainTags <- parseChain(inputRow$pfx)
  chainTagsWithFills <- inner_join(chainTags,
                                   tabulatedModels %>% select(ordinal, network, FloorPrice, Fill=value),
                                   by=c("network","FloorPrice","ordinal"))
  chainTagsWithFills$FillSource <- "model"
  currentTagRow <- inputRow[1,c("ordinal","network","FloorPrice","Fill")]
  currentTagRow$FillSource <- "actual"
  result <- rbind(chainTagsWithFills, currentTagRow)
  result$groupingTag <- paste0(inputRow$network,inputRow$FloorPrice)
  return(result)
}

testCalcCorrel <- function () {
  inputs <- loadAllInputs()
  fills <- loadAllFillTables()

  sampleRow <- inputs[inputs$ordinal==2,][1,]
  df <- singleChainToDF(sampleRow, fills)
}