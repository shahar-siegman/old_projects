library(plyr)
session4 <- function(DF) {
  ddply(DF %>% select(placement_id, date, impressions, served), "placement_id", predictionDF)
}


predictionDF <- function(DF) {
  # input is a data frame subset to one timeseries (e.g. one placementid)
  # it is designed to be used in a ddply call.
  # the output is a data frame with additional columns for the predicitons
  # rollapllyr will be used to construct the time-series-style predictions
  DF %>% mutate(
    smooth_imps = lag(rollapplyr(impressions, 14, sum, partial=T, align="right"),1),
    smooth_served = lag(rollapplyr(served, 14, sum, partial=T, align="right"),1),
    smooth_fill = smooth_served / smooth_imps,
    predict_served = impressions * smooth_fill,
    resid_served = served - predict_served
  )
}
