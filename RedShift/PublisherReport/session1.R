source('../../libraries.R')

getData <- function()
{
  read.csv('kettle_out.csv', stringsAsFactors = F)
}

preprocess <- function(df, filterWeirdDays=T, filterWeirdNetworks=F)
{
  goodNetworks <- c("o","p","t")
  weirdNetworks <- c("e","j","x","z")
  networks <- goodNetworks
  if (!filterWeirdNetworks)
    networks <- c(networks,weirdNetworks)
  df3 <- df %>% mutate(plcmnt_joined = ifelse(placement_id=="",placement_id_1, placement_id))
  df3 <- df3 %>% mutate(tag=ifelse(code=="",served_tag_network,code))
  df3 <- df3 %>% mutate(date=ifelse(date=="", date_1,date))
  df3 <- df3 %>%  filter(tag %in% networks, as.Date(date) <='2016-03-12')
  df3 <- df3 %>% select(plcmnt_joined, date, tag, cnt, served, impressions) %>%
    rename(placement_id=plcmnt_joined) %>% mutate(code=tag)
  if (filterWeirdDays)
    df3 <- df3 %>% filter(!(as.Date(date) %in% as.Date(c('2016-03-03','2016-03-04','2016-03-05'))))
  return(df3)
}

summarisePlacementNetwork <- function()
{
  df4 <- getData() %>% preprocess() %>% group_by(placement_id,tag) %>%
    summarise(cnt=sum(cnt, na.rm=T), served=sum(served, na.rm=T))
  df4 <- df4 %>% filter(cnt + served >= 500)
  df4 <- df4 %>% mutate(rs_bias = ifelse(cnt<served,cnt/served-1, 1-served/cnt))
  return(df4)
}

analysis1 <- function()
{ # plot histogram per network
  df1 <- summarisePlacementNetwork()
  ggplot(df1) + geom_histogram(aes(x=rs_bias)) + facet_grid(~tag)
}

calcRsBias <- function(...)
{ #
  df <- getData() %>% preprocess(...)
  df1 <- summarisePlacementNetwork() %>% select(placement_id, tag)
  df2 <- inner_join(df, df1, by=c("placement_id","tag"))
  df2 <- df2 %>% mutate(rs_bias = ifelse(cnt<served,cnt/served-1, 1-served/cnt))
  return(df2)
}

analysis2 <- function()
{ # plot bias over time
  df2 <- calcRsBias()
  ggplot(df2) +  geom_abline(slope=0, intercept=0, colour="gray") +
    geom_path(aes(x=date, y=rs_bias, group=tag, colour=tag)) +
    facet_wrap( ~ placement_id) + coord_cartesian(ylim=c(-0.3,0.3))
}

analysis3 <- function()
{ #
  df2 <- calcRsBias()
  df2 <- df2 %>% arrange(date) %>% group_by(placement_id,tag) %>% mutate(lag_served=lag(served)) %>% ungroup()
  df2 <- df2 %>% mutate(lag_bias = ifelse(lag_served<served,lag_served/served-1, 1-served/lag_served))
  ggplot(df2) +  geom_abline(slope=0, intercept=0, colour="gray") +
    geom_path(aes(x=date, y=lag_bias, group=tag, colour=tag)) +
    facet_wrap( ~ placement_id) + coord_cartesian(ylim=c(-0.3,0.3))
}

servedBiasMovingAveragePrediction <- function(w, ...)
{
  df2 <- calcRsBias(...)
  df2 <- df2 %>% arrange(date) %>% group_by(placement_id,tag) %>%  mutate(lag_rs_bias=lag(rs_bias)) %>% ungroup()
  df3 <- df2 %>% arrange(placement_id, tag, date)
  df3 <- df3 %>% mutate(bias_pred=rollapply(data = lag_rs_bias, width = w, mean, na.rm=T, partial=T, fill=NA, align="right"))
  df3 <- df3 %>% mutate(pred_served = ifelse(bias_pred>0,(1-bias_pred)*cnt,cnt/(bias_pred+1)))
  df3 <- df3 %>% mutate(pred_bias = ifelse(pred_served < served, pred_served/served-1, 1-served/pred_served))
}

calcBias <- function(df,colA, colB)
{
  df[[paste0(colA,"_bias")]] <- ifelse(df[[colA]] < df[[colB]], df[[colA]]/df[[colB]]-1, 1- df[[colB]]/df[[colA]])
  return(df)
}

analysis4 <- function(Print=F, w=4, ...)
{ # create a prediction of the bias based on moving average
  df3 <- servedBiasMovingAveragePrediction(w, ...)
  p <-  ggplot(df3) +  geom_abline(slope=0, intercept=0, colour="gray") +
    geom_path(aes(x=date, y=pred_bias, group=tag, colour=tag)) +
    facet_wrap( ~ placement_id) #+ coord_cartesian(ylim=c(-0.3,0.3))
  if (Print)
    print(p)
  return(df3)
}

analysis5 <- function()
{
  df3 <- servedBiasMovingAveragePrediction(w=1, filterWeirdNetworks=T)
  predBias <- df3 %>% filter(pred_bias >=-1, pred_bias <=1) %>% group_by(placement_id,date) %>%
    summarise(served=sum(served),pred_served=sum(pred_served)) %>% calcBias("pred_served","served") %>%
    `[[`("pred_served_bias")
  result <- data.frame()
  cnt <- length(predBias)
  for (i in 1:20) {
    predErrWithSafetyMargin = predBias -i/100
    result <- rbind(result,data.frame(
      safety_margin=i,
      severe_down = sum(predErrWithSafetyMargin <= -0.15)/cnt,
      reasonable_down = sum(predErrWithSafetyMargin > -0.15 & predErrWithSafetyMargin <= 0)/cnt,
      reasonable_up = sum(predErrWithSafetyMargin > 0 & predErrWithSafetyMargin <= 0.1)/cnt,
      severe_up = sum(predErrWithSafetyMargin > 0.1) / cnt
    ))
  }
  return(result)
}
