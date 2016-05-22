lagDailyTagEcpm <- function() {
  # during most of the day, yesterday's data is not yet available, hence lag 2
  tagData <- getListTagData() %>% preprocess2()
  tagData <- tagData %>% arrange(placement_id, tag_name, floor_price, date_joined) %>%
    group_by(placement_id, tag_name, floor_price) %>%
    mutate(ecpm=1000*income/served, ecpm_lag=lag(ecpm,2)) %>% ungroup()
  return(tagData)
}

readPlacementSiteTable <- function() {
  read.csv("placements_sites.csv", stringsAsFactors = F)
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

compareLagPredictions <- function(predictionLevel="p")
{
  granularDataType="network"
  predictByWhat <- c(p="placement_id", s="sitename")
  placementData <- lagDailyPlacementEcpm()
  if (granularDataType=="network")
    granularData <- lagDailyNetworkEcpm()
  else
    granularData <- lagDailyTagEcpm()

  predictedByGranular <- granularData %>%
    mutate(pred_income = served*ecpm_lag/1000) %>%
    group_by(placement_id, date_joined) %>%
#    summarise(pred_income_net=sum(pred_income), served_net=sum(served)) %>%
#    mutate(pred_ecpm_net = 1000*pred_income_net/served_net) %>%
    ungroup()
  predictedByPlacement <- placementData %>% mutate(pred_income_plcmnt = served*ecpm_lag/1000)
  if (predictionLevel=="s") {
    predictedByPlacement <- inner_join(predictedByPlacement, readPlacementSiteTable(), by="placement_id")
    predictCompare <- predictedByPlacement %>% group_by_(predictByWhat[predictionLevel],"date_joined") %>%
      summarise(pred_income_plcmnt = sum(pred_income_plcmnt),
                income_plcmnt=sum(income_plcmnt),
                served=sum(served))
  }
  else
  {
    predictCompare <- predictedByPlacement
  }
#  predictCompare <- left_join(predictedByPlacement, predictedByGranular, by=c("placement_id", "date_joined"))
  predictCompare <- calcBias(predictCompare,"pred_income_plcmnt","income_plcmnt")
#  predictCompare <- calcBias(predictCompare,"pred_income_net","income_plcmnt")
  return(predictCompare)
}

#analysis8 was rended unusable by upstream code changes

analysis9 <- function()
{
  # computes "pred_served" and "pred_served_bias", the predicted # of served per network and the err term
  # counts placement*day for each category
  servedPrediction <- servedPredictionSummaryDf()
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

analysis10 <- function(y="p")
{
  err_thres <- c(0.1, 0.2, 0.4)
  plcmnt_err_count_tol <- 0.15
  small_plcmnt_day_dollar_amount <- 10
  groupByWhat <- c(p="placement_id",s="sitename")

  print(1)
  servedPrediction <- servedPredictionSummaryDf(y)
  revenueData <- compareLagPredictions(y) %>% select_(groupByWhat[y], "date_joined", "served", "income_plcmnt", "pred_income_plcmnt_bias") %>%
    rename(served_tagdata=served, date=date_joined)
  joined <- inner_join(servedPrediction, revenueData, by=unname(c(groupByWhat[y],"date")))
  print(2)
  #placementSites <- readPlacementSiteTable()
  #joined <- inner_join(joined, placementSites, by="placement_id")

  df <- joined %>% mutate(errcat1=ifelse(abs(pred_income_plcmnt_bias) < err_thres[1],1,0),
                          errcat2=ifelse(abs(pred_income_plcmnt_bias) < err_thres[2],1,0),
                          errcat3=ifelse(abs(pred_income_plcmnt_bias) < err_thres[3],1,0),
                          errcat_other=ifelse(errcat1 | errcat2 | errcat3, 0, 1),
                          is_small_day = ifelse(abs(income_plcmnt) < small_plcmnt_day_dollar_amount,1,0))
  df1 <- df %>% group_by_(groupByWhat[y]) %>% summarise(days_errcat1=sum(errcat1, na.rm=T)/n(),
                                         days_errcat2=sum(errcat2, na.rm=T)/n(),
                                         days_errcat3=sum(errcat3, na.rm=T)/n(),
                                         days_errcat_other=sum(errcat3, na.rm=T)/n(),
                                         days_small=sum(is_small_day, na.rm=T)/n(),
                                         cnt = n()) %>% filter(cnt>=7)

  # df1 <- df1 %>% mutate(plcmnt_errcat1 = ifelse(days_errcat1>= cnt*(1-plcmnt_err_count_tol),1,0),
  #                    plcmnt_errcat2 = ifelse(days_errcat2>= cnt*(1-plcmnt_err_count_tol),1,0),
  #                    plcmnt_errcat3 = ifelse(days_errcat3>= cnt*(1-plcmnt_err_count_tol),1,0),
  #                    plcmnt_small= ifelse(days_small>= cnt*0.9, 1,0))

  #print(sum(df$errcat_other, na.rm=T)/sum(!is.na(df$errcat_other)))

  return(df1)
}

analysis11 <- function()
{
  quantileCutoff <- 0.9
  servedPrediction <- servedPredictionSummaryDf()
  revenueData <- compareLagPredictions() %>% select(placement_id, date_joined, served, income_plcmnt, pred_income_plcmnt_bias) %>%
    rename(served_tagdata=served, date=date_joined)
  joined <- inner_join(servedPrediction, revenueData, by=c("placement_id","date"))
  df1 <- joined %>% group_by(placement_id) %>%
    summarise(acc_70 = quantile(abs(pred_income_plcmnt_bias),0.7, na.rm=T),
              acc_80 = quantile(abs(pred_income_plcmnt_bias),0.8, na.rm=T),
              acc_90 = quantile(abs(pred_income_plcmnt_bias),0.9, na.rm=T))
  return(df1)
}


#servedPredict <- servedBiasMovingAveragePrediction(1)