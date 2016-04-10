getModelOrderZeroFillForChains <- function(inputDF, modelDF, orderCutOff)
{
  inputDF <- inputDF %>% mutate(pfx = str_replace_all(pfx,"[\\[\\]]",""))

  withDate = "date" %in% names(inputDF)

  selectCols <- c("chain","Fill")
  if (withDate) {
    otherJoinCols <- c("date"="date")
    selectCols <- c(selectCols,"date")
  }
  else
  {
    otherJoinCols <- c()
  }

  inputDF <- inputDF %>%
    mutate(thisTag = paste0(network, sprintf("%.2f",FloorPrice)),
           chain = paste0(pfx,ifelse(pfx=="","",":"), thisTag))

  inputDF <- getModelOrdinalZeroFillForCurrentTag(inputDF, modelDF)
  return(inputDF)
}



runAttenuation <- function(inputPath="data/2016-02-14_2016-02-29/8da340850358268699f237d00c683198/Final") {
  optionSet <- data.frame(use_s=T,
                          use_fill=F,
                          use_pass=T,
                          order=5,
                          inputPath = inputPath,
                          stringsAsFactors=F)
  inputs <- loadAllInputs(optionSet$inputPath)
  tabulatedModels <- loadAllFillTables(optionSet$inputPath)
  options <- mergeByName(optionDefault, optionSet)
  integrate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    filter(served > 10 & impressions > 10) %>% mutate(Fill = served/ impressions) %>% ungroup()
  options$order=2


  p <- getModelOrderZeroFillForChains(integrate, tabulatedModels)
  p <- p %>% mutate(atten= (1-Fill)/(1-Fill.Model) - 1
                    , st=ifelse(network=="t",str_count(pfx,"t"),0)
                    , se=ifelse(network=="e",str_count(pfx,"e"),0)
                    , sp=ifelse(network=="p",str_count(pfx,"p"),0)
                    , d= as.numeric(as.character(ordinal))-(st+se+sp))
  t <- lm(atten ~ st+se+sp+d+0,p)
  print(t)
  print(AIC(t))
  print(r2(t))
  p$fitted= t$fitted.values
  p$residuals = t$residuals
  return(p)
}


