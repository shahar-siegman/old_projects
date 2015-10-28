library(plyr)
library(dplyr)
library(zoo)
library(ggplot2)
cutoffDate <- as.Date("2015-09-28")

session4 <- function(DF) {

  DF <- DF %>% select(placement_id, date, impressions,served, kserved=komoona_served) %>% filter(impressions>500, served>40)
  DF$date <- as.Date(DF$date,format="%m/%d/%Y")
  DF <- predict1DayFwdAllPlacements(DF, key = "placement_id", series=c("impressions","served","fill"))
  DF <- predict1DayFwdAllPlacements(DF, key = "placement_id", series=c("impressions","kserved","komoona_fill"))
  DF <- DF %>% rename(predict_served_stage1 = predict_served)
  #DF$served_resid <- DF$predict_served - DF$served
  #DF$kserved_resid <- DF$predict_kserved - DF$kserved

  DF$served_rel <- DF$predict_served / DF$served
  DF$kserved_rel <- DF$predict_kserved / DF$kserved
  DF$period <- ifelse(DF$date <= cutoffDate, 1, 2)
  DF <- addSlopeColumn(DF,
                       DF %>% filter(period==1) %>% select(placement_id, x=kserved_rel, y=served_rel),
                       "placement_id")
  DF <- DF %>% select(-placement_id.y) # drop redundant column
  #DF$serv_resid_predict <- DF$slope * DF$kserved_resid
  #DF$serv_rel_predict <- DF$slope * DF$kserved_rel

  DF$predict_served_stage2 <- DF$predict_served_stage1 / DF$kserved_rel


  # plot the linear regressions
  p1 <- ggplot(DF, aes(x=kserved_rel, y=served_rel, color=as.numeric(date-max(date)))) +
    geom_point() +
    facet_wrap(~placement_id,scale="free") +
    geom_abline(intercept=0, slope=1, colour="pink") +
    geom_abline(aes(intercept=0,slope=slope), colour="blue") +
    xlim(c(0,3))+ylim(c(0,3))
  #geom_smooth(method='lm',formula=y~x + 0, na.rm=T) +

  # plot the residual before-and-after linear regression
  p2 <- ggplot(DF) +
    geom_density(aes(x=log(predict_served_stage1 / served), y=..scaled..),fill="red", alpha=0.2) +
    geom_density(aes(x=log(predict_served_stage2 / served), y=..scaled..),fill="blue", alpha=0.5) +
    geom_vline(xintercept=0, colour="black") +
    facet_wrap(~placement_id, scale="free")

  # plot the error density before-and-after residual correction

  p3 <- ggplot(DF) +
    geom_density(aes(x=served_resid, y=..scaled..), fill="red", alpha=0.2) +
    geom_density(aes(x=served - served_predict, y=..scaled..), fill="blue", alpha=0.5) +
    geom_vline(xintercept=0, colour="black") +
    facet_wrap(~placement_id, scale="free")
  #print(p1)
  #print(p2)
  return(list(p1,p2,p3,DF))
}

predict1DayFwdAllPlacements <- function(DF, key , series) {
  a <- ddply(DF, key, predict1Day1Placement, series)
  return(a)
}
# {
#   b <- ddply(DF %>% select(placement_id, date, impressions,served=komoona_served), "placement_id", predictServed1DayAhead)
#   b <- b %>% select(placement_id, date, komoona_served=served, smooth_kserved = smooth_served,
#                     smooth_kfill = smooth_fill, resid_kserved = resid_served)
#   DF1 <- inner_join(a,b) # , by=c("placement_id","date")
#   return (DF1)
# }

addSlopeColumn <- function(DF, regressionDF, groupColumn) {
  a <- ddply(regressionDF, groupColumn, my_lm) %>% rename()
  b <- left_join(DF,a,by=setNames("key",groupColumn))
  return(b)
}


predict1Day1Placement <- function(DF, series) {
  # input is a data frame subset to one timeseries (e.g. one placementid)
  # it is designed to be used in a ddply call.
  # the output is a data frame with additional columns for the predicitons
  # rollapllyr will be used to construct the time-series-style predictions
  #print(paste("Next placement: ", DF[1,1]))
  imps <- series[1]
  served <- series[2]
  fill <- series[3]
  smooth_imps = paste("smooth_",imps, sep="")
  smooth_served = paste("smooth_",served, sep="")
  predict_served = paste("predict_", served, sep="")
  smooth_fill = paste("smooth_", fill, sep="")

  DF[,smooth_imps] <- lag(rollapply(DF[,imps], 14, sum, partial=T, align="right"),1)
  DF[,smooth_served] <- lag(rollapply(DF[,served], 14, sum, partial=T, align="right"),1)
  DF[,smooth_fill] <- DF[,smooth_served] / DF[,smooth_imps]
  DF[,predict_served] <- DF[,imps] * DF[,smooth_fill]
  return(DF)
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

# predictResid<- function(df1) {
#   # predict the residual of `served` using the residual of `kmn_served`
#   df12 <- left_join(df1,df2,by="placement_id")
#   df12$predict_served_ <- df12$predict_served - df12$slope * df12$resid_kserved
#   df12$resid2_served <- df12$predict2_served - df12$served
#   return(df12)
# }
