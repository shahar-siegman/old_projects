library(plyr)
library(dplyr)
library(zoo)
library(ggplot2)

session4 <- function(DF) {
  df1 <- calcResiduals(DF)
  df2 <- calcRegressionLine(df1)
  p <- ggplot(df1, aes(x=resid_kserved,y=resid_served)) +
    geom_point() +
    facet_wrap(~placement_id,scale="free") +
    geom_smooth(method='lm',formula=y~x + 0, na.rm=T)
  print(p)
  return(df2)
}

calcResiduals <- function(DF) {
  a <- ddply(DF %>% select(placement_id, date, impressions,served), "placement_id", predictionDF2)
  b <- ddply(DF %>% select(placement_id, date, impressions,served=komoona_served), "placement_id", predictionDF2)
  b <- b %>% select(placement_id, date, komoona_served=served, smooth_kserved = smooth_served,
                    smooth_kfill = smooth_fill, resid_kserved = resid_served)
  DF1 <- inner_join(a,b) # , by=c("placement_id","date")
  return (DF1)
}

calcRegressionLine <- function(DF) {
  a <- ddply(DF %>% select(placement_id, x=resid_kserved, y=resid_served), "placement_id", lm_eqn)
  return(a)
}



predictionDF <- function(DF) {
  # input is a data frame subset to one timeseries (e.g. one placementid)
  # it is designed to be used in a ddply call.
  # the output is a data frame with additional columns for the predicitons
  # rollapllyr will be used to construct the time-series-style predictions
  #print(paste("Next placement: ", DF[1,1]))
  DF <- DF %>% mutate(
    smooth_imps = lag(rollapply(impressions, 14, sum, partial=T, align="right"),1),
    smooth_served = lag(rollapply(served, 14, sum, partial=T, align="right"),1),
    smooth_fill = smooth_served / smooth_imps)
}

# myddply<- function(df,grouping_column, func)
# {
#   index <- df[,grouping_column]
#   indices <- tapply(index, index)
#   levels <- max(indices)
#   outputDF <- data.frame()
#   for (i in 1:levels) {
#     currentSubset <- indices == i
#     currentInputDF <- df[currentSubset,]
#     currentOutputDF <- func(currentInputDF)
#     outputDF <- rbind(outputDF,currentOutputDF)
#   }
#   return(outputDF)
# }


predictionDF2 <- function(DF) {
  # input is a data frame subset to one timeseries (e.g. one placementid)
  # it is designed to be used in a ddply call.
  # the output is a data frame with additional columns for the predicitons
  # rollapllyr will be used to construct the time-series-style predictions
  #print(paste("Next placement: ", DF[1,1]))
  DF$smooth_imps <- lag(rollapply(DF$impressions, 14, sum, partial=T, align="right"),1)
  DF$smooth_served <- lag(rollapply(DF$served, 14, sum, partial=T, align="right"),1)
  DF$smooth_fill <- DF$smooth_served / DF$smooth_imps
  DF$predict_served <- DF$impressions * DF$smooth_fill
  DF$resid_served <- DF$served - DF$predict_served
  return(DF)
}


lm_eqn <- function(df) {
  m <- lm(y ~ x + 0, df, na.action= na.exclude)
  df1 <- data.frame(placement_id=df[1,1], slope = coef(m)[1], r2= summary(m)$r.squared)
  #df1 <- data.frame(placement_id=df[1,1], slope = coef(m)[2], intecept=coef(m)[1], r2= summary(m)$r.squared)
  return(df1)
}
