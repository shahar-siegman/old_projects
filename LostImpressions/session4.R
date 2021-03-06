library(plyr)
library(dplyr)
library(zoo)
library(ggplot2)

runSession4 <- function() {
currdir = 'C:/Shahar/Projects/LostImpressions/'
rawDF <- read.csv(paste(currdir,'sample_placement_data_with_komoona_served.csv',sep=""))
a <- session4Plots(session4(rawDF))
write.csv(a[[3]], paste(currdir,'sample_fill_prediction.csv'))
return(a)
}

session4 <- function(DF) {
  DF <- DF %>% transmute(placement_id, date, impressions, served, kserved=komoona_served, komooona_fill=komoona_served/impressions) %>% filter(impressions>500, served>40)
  DF$date <- as.Date(DF$date,format="%Y-%m-%d")
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("impressions","served","fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("impressions","komoona_served","komoona_fill"))
  DF$komoona_fill_factor <- DF$smooth_fill/DF$smooth_komoona_fill
  DF$predict_served_stage1 <- DF$smooth_fill * DF$impressions

  DF$predict_served <- DF$smooth_fill * DF$kserved / DF$smooth_komoona_fill
  DF$predict_kserved <- DF$smooth_komoona_fill * DF$impressions
  DF$served_rel <- DF$predict_served / DF$served
  DF$kserved_rel <- DF$predict_kserved / DF$kserved

  return(DF)
}

session4Plots <- function(DF) {
  # plot the linear regressions
  p1 <- ggplot(DF, aes(x=kserved_rel, y=served_rel, color=as.numeric(date-max(date)))) +
    geom_point() +
    facet_wrap(~placement_id,scale="free") +
    geom_abline(intercept=0, slope=1, colour="pink") +
    xlim(c(0,3))+ylim(c(0,3))

  # plot the residual before-and-after linear regression
  p2 <- ggplot(DF) +
    geom_density(aes(x=log(predict_served_stage1 / served), y=..scaled..),fill="red", alpha=0.2) +
    geom_density(aes(x=log(predict_served / served), y=..scaled..),fill="blue", alpha=0.5) +
    geom_vline(xintercept=0, colour="black") +
    facet_wrap(~placement_id)

  # plot the error density before-and-after residual correction

#   p3 <- ggplot(DF) +
#     geom_density(aes(x=served_resid, y=..scaled..), fill="red", alpha=0.2) +
#     geom_density(aes(x=served - served_predict, y=..scaled..), fill="blue", alpha=0.5) +
#     geom_vline(xintercept=0, colour="black") +
#     facet_wrap(~placement_id, scale="free")
  return(list(p1,p2,DF))
}

learnHistoricalRateAllPlacements <- function(DF, key , series) {
  a <- ddply(DF, key, learnHistoricalRate1Placement, series)
  return(a)
}


advancePredictionInTimeAllPlacements <- function(DF, key, series) {
  a <- ddply(DF, key, advancePrediction1Placement, series)
  return(a)
}

learnHistoricalRate1Placement <- function(DF, series) {
  # input is a data frame subset to one timeseries (e.g. one placementid)
  # it is designed to be used in a ddply call.
  # the output is a data frame with additional columns for the predicitons
  # rollapllyr will be used to construct the time-series-style predictions
  denom <- series[1]
  num <- series[2]
  rate <- series[3]
  smooth_denom = paste("smooth_", denom, sep="")
  smooth_num = paste("smooth_", num, sep="")
  smooth_rate = paste("smooth_", rate, sep="")

  DF[,smooth_num] <- lag(rollapply(DF[, num], 14, mean, partial=T, align="right"),1)
  if (denom!="") {
    DF[,smooth_denom] <- lag(rollapply(DF[, denom], 14, mean, partial=T, align="right"),1)
    DF[,smooth_rate] <- DF[,smooth_num] / DF[,smooth_denom]
  }
  return(DF)
}

advancePrediction1Placement <- function(DF,series) {
  smoothed <- series[1]
  actual <- series[2]
  predictionRatio <- paste(actual,"_prediction_factor", sep="")
  DF[,predictionRatio] <- DF[,actual]/DF[,smoothed]
}

my_lm <- function(df) {
  if (nrow(df)>=3) {
    m <- lm(y ~ x + 0, df, na.action= na.exclude)
    slope <- coef(m)[1]
    r2 <- summary(m)$r.squared
  }
  else {
    slope <- 0
    r2 <- 0
  }
  df1 <- data.frame(key=df[1,1], slope = slope, r2= r2)
  return(df1)
}

