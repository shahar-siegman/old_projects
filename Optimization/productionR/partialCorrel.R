
partialCorrel <- function() {
  optionSet <- data.frame(use_s=T,
                           use_fill=F,
                           use_pass=T,
                           order=2,
                           inputPath = "data/2016-02-14_2016-02-29/8da340850358268699f237d00c683198/Final",
                           stringsAsFactors=F)
  inputs <- loadAllInputs(optionSet$inputPath)
  tabulatedModels <- loadAllFillTables(optionSet$inputPath)
  options <- mergeByName(optionDefault, optionSet)
  integrate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    filter(served > 10 & impressions > 10) %>% mutate(Fill = served/ impressions) %>% ungroup()
  options$order=2
  joinedFills <- getFillsForAllPreChains(integrate,options$order)
  joinedFills <- getModelOrdinalZeroFillForCurrentTag(joinedFills,tabulatedModels)

  scoreDF <- calcOrderCoeffs(joinedFills, options)


}