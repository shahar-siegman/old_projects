currdir = 'C:/Shahar/Projects/LostImpressions/'

source(paste(currdir,'session4.R',sep=""))

runSession5 <- function() {
  currdir = 'C:/Shahar/Projects/LostImpressions/'
  rawDF <- read.csv(paste(currdir,'experiment_data_chainlevel.csv',sep=""))
  a <- session5Plots(session5(rawDF))
  write.csv(a[[1]], paste(currdir,'mobile_experiment_served_prediction.csv',sep=""))
  return(a)
}


session5 <- function(DF) {
  #DF <- DF %>% select(placement_id, date, impressions,served, kserved=komoona_served) %>% filter(impressions>500, served>40)
  DF$date <- as.Date(DF$date,format="%Y-%m-%d")
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","nondescript_chain"), series=c("true_global_imps","true_global_served","global_fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","nondescript_chain"), series=c("true_global_imps","nd_kimpressions","global_komoona_fill"))
  DF$komoona_fill_factor <- DF$smooth_global_fill/DF$smooth_global_komoona_fill
  DF$predict_mobile_served <- DF$komoona_fill_factor * DF$mobile_kserved
  DF$resid_mobile_served <- DF$predict_mobile_served/ DF$true_mobile_served - 1
  DF$serv_ratio_global <- DF$true_global_served/DF$nd_kserved
  DF$serv_ratio_mobile <- DF$true_mobile_served / DF$mobile_kserved
  return(DF)
}

session5Plots <- function(DF) {
  p2 <- ggplot(DF) +
    geom_density(aes(x=resid_mobile_served, y=..scaled..), fill="blue", alpha=0.5) +
    facet_wrap(~placement_id) +
    coord_cartesian(xlim=c(-1,1))
  p3 <- ggplot(DF) + geom_point(aes(x=komoona_fill_factor,y=resid_mobile_served)) +  facet_wrap(~placement_id)

  p4 <- ggplot(DF) +
    geom_line(aes(x=date,y=serv_ratio_global,color=nondescript_chain)) +
    geom_line(aes(x=date,y=serv_ratio_mobile,color=nondescript_chain)) +
    coord_cartesian(ylim=c(0,2)) +
    facet_wrap(~placement_id)
  return(list(DF,p2,p3,p4))
}