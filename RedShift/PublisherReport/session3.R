lagDailyNetworkEcpm <- function() {
  networkData <- getListTagData() %>% preprocess2()
  networkData <- networkData %>% group_by(placement_id, date_joined, code) %>%
    summarise(served=sum(served), income=sum(income))
  networkData <- networkData %>% arrange(placement_id, code, date_joined) %>%
    group_by(placement_id, code) %>%
    mutate(ecpm=1000*income/served, ecpm_lag=lag(ecpm)) %>% ungroup()

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

compareLagPredictions <- function()
{
  placementData <- lagDailyPlacementEcpm()
  networkData <- lagDailyNetworkEcpm()

  predictedByNetwork <- networkData %>%
    mutate(pred_income = served*ecpm_lag/1000) %>%
    group_by(placement_id, date_joined) %>%
    summarise(pred_income_net=sum(pred_income), served_net=sum(served)) %>%
    mutate(pred_ecpm_net = 1000*pred_income_net/served_net) %>%
    ungroup()
  predictedByPlacement <- placementData %>% mutate(pred_income_plcmnt = served*ecpm_lag/1000)

  predictCompare <- left_join(predictedByPlacement, predictedByNetwork, by=c("placement_id", "date_joined"))
  predictCompare <- calcBias(predictCompare,"pred_income_plcmnt","income_plcmnt")
  predictCompare <- calcBias(predictCompare,"pred_income_net","income_plcmnt")
  return(predictCompare)
}

#servedPredict <- servedBiasMovingAveragePrediction(1)