currdir = 'C:/Shahar/Projects/LostImpressions/'

source(paste(currdir,'session4.R',sep=""))


session5 <- function(DF) {
  DF <- DF %>% select(placement_id, date, impressions,served, kserved=komoona_served) %>% filter(impressions>500, served>40)
  DF$date <- as.Date(DF$date,format="%m/%d/%Y")
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("impressions","served","fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("impressions","kserved","komoona_fill"))
  DF$komoona_fill_factor <- DF$smooth_fill/DF$smooth_komoona_fill
  DF$predict_mobile_served <- DF$komoona_fill_factor * DF$mobile_kserved
  return(DF)
}