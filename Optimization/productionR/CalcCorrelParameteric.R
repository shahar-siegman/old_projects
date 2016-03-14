calcCorrelSequence <- function(optionSets)
{
  nRuns <- min(nrow(optionSets))
  metaResult <- data.frame()
  for (i in 1: nRuns) {
    currInputPath <- optionSets$inputPath[[i]]
    currOption <- optionSets[i,] %>% select(-inputPath)
    currOrder <- currOption$order
    res <- runCalcCorrel(currOrder, currInputPath, currOption)
    metaResult = rbind(metaResult,cbind(
      data.frame(path = currInputPath),
      as.data.frame(currOption),
      data.frame(r2=sprintf("%0.4f",res$r2)),
      as.data.frame(
        list(fill=NA,base=NA,s=NA,d=NA) %>%
          mergeByName(res$by.lm$coefficients) %>%
          t()
      ),
      data.frame(k=res$AIC[1], AIC=res$AIC[2])
    ))
  }

  return(metaResult)
}

runCalcCorrelSequence <- function()
{
  inputPaths <- list (
    "data/2016-02-14_2016-02-29/8da340850358268699f237d00c683198/Final",
    "data/2016-02-14_2016-02-29/240cbcbcb94241d8e7a6581589db6f64/Final",
    "data/2015-09-15_2015-09-30/66efa8ef06355f0c70da35c246b2e07d/Final"
  )

  optionSets <- expand.grid(list(
    use_s=c(T,F),
#    correlation=c(T,F),
    use_fill=c(T,F),
    use_pass=c(T,F),
    order=c(1,2),
    inputPath=inputPaths
    )) %>% filter(use_fill | use_pass)
  return(calcCorrelSequence(optionSets))
}