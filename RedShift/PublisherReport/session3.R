lagDailyTagEcpm <- function() {
  # during most of the day, yesterday's data is not yet available, hence lag 2
  tagData <- getListTagData() %>% preprocess2()
  tagData <- tagData %>% arrange(placement_id, tag_name, floor_price, date_joined) %>%
    group_by(placement_id, tag_name, floor_price) %>%
    mutate(ecpm=1000*income/served, ecpm_lag=lag(ecpm,2)) %>% ungroup()

  return(tagData)
}

lagDailyNetworkEcpm <- function() {
  networkData <- getListTagData() %>% preprocess2()
  networkData <- networkData %>% group_by(placement_id, date_joined, code) %>%
    summarise(served=sum(served), income=sum(income))
  networkData <- networkData %>% arrange(placement_id, code, date_joined) %>%
    group_by(placement_id, code) %>%
    mutate(ecpm=1000*income/served, ecpm_lag=lag(ecpm,2)) %>% ungroup()

  return(networkData)
}


lagDailyPlacementEcpm <- function() {
  networkData <- getListTagData() %>% preprocess2()
  placementData <- networkData %>% group_by(placement_id, date_joined)  %>%
    summarise(served=sum(served), income_plcmnt=sum(income)) %>%
    mutate(ecpm=1000*income_plcmnt/served)
  placementData <- placementData %>%
    arrange(placement_id, date_joined) %>%
    group_by(placement_id) %>%
    mutate(ecpm_lag=lag(ecpm)) %>% ungroup()

  return(placementData)
}

compareLagPredictions <- function(granularDataType="network")
{
  placementData <- lagDailyPlacementEcpm()
  if (granularDataType=="network")
    granularData <- lagDailyNetworkEcpm()
  else
    granularData <- lagDailyTagEcpm()

  predictedByGranular <- granularData %>%
    mutate(pred_income = served*ecpm_lag/1000) %>%
    group_by(placement_id, date_joined) %>%
    summarise(pred_income_net=sum(pred_income), served_net=sum(served)) %>%
    mutate(pred_ecpm_net = 1000*pred_income_net/served_net) %>%
    ungroup()
  predictedByPlacement <- placementData %>% mutate(pred_income_plcmnt = served*ecpm_lag/1000)

  predictCompare <- left_join(predictedByPlacement, predictedByGranular, by=c("placement_id", "date_joined"))
  predictCompare <- calcBias(predictCompare,"pred_income_plcmnt","income_plcmnt")
  predictCompare <- calcBias(predictCompare,"pred_income_net","income_plcmnt")
  return(predictCompare)
}

analysis8 <- function()
{
  b <- compareLagPredictions("tag")
  ggplot(b) +
    geom_line(aes(x=date_joined, y=pred_income_plcmnt_bias, group=placement_id),colour="grey") +
    geom_line(aes(x=date_joined, y=pred_income_net_bias, group=placement_id),colour="blue") +
    facet_wrap(~placement_id) +
    coord_cartesian(ylim=c(-0.1,0.1))
}

analysis9 <- function()
{
  servedPrediction <- servedPredictionSummaryDf() # %>% `[[`("pred_served_bias")
  revenueData <- compareLagPredictions() %>% select(placement_id, date_joined, served, income_plcmnt) %>%
    rename(served_tagdata=served, date=date_joined)
  joined <- inner_join(servedPrediction, revenueData, by=c("placement_id","date"))
  result <- data.frame()
  cnt <- nrow(joined)
  smallPlcmntDay <- "reg" #as.factor(ifelse(joined$income_plcmnt < 15, "small","reg"))
  num <- nrow(joined)
  for (i in 1:20) {
    predErrWithSafetyMargin = joined$pred_served_bias -i/100
    category <- ifelse(predErrWithSafetyMargin <=0,
                       ifelse(predErrWithSafetyMargin >=-0.05, "down_less_than_5pct_error",
                          ifelse(predErrWithSafetyMargin >=-0.15, "down_less_than_15pct_error",
                                 "down_more_than_15pct")),
                       ifelse(predErrWithSafetyMargin <= 0.05, "up_less_than_5pct",
                              ifelse(predErrWithSafetyMargin <= 0.15, "up_less_than_15pct",
                                     "up_more_than_15pct")))


    counts <- data.frame(small=smallPlcmntDay, cat=as.factor(category)) %>%
      group_by(small, cat) %>%
      summarise(cnt=n()) %>% mutate(name=paste0(small,"_",cat))
    countsList <- counts$cnt
    names(countsList) <- counts$name
    countDF <- data.frame(countsList)
    result <- rbind(result,
                    data.frame(i=i, as.data.frame(as.list(countsList))/num))
  }
  return(result)
}



#servedPredict <- servedBiasMovingAveragePrediction(1)