currdir = 'C:/Shahar/Projects/LostImpressions/'

source(paste(currdir,'session4.R'))
rawDF <- read.csv(paste(currdir,'kettle_placement_data_with_komoona_served.csv'))
rawDF <- rawDF %>% select(placement_id, date, served,
                          impressions=mobile_impressions,
                          komoona_served=mobile_kserved,
                          )
a <- session4(rawDF)
write.csv(a[[4]], paste(currdir,'mobile_fill_prediction')


session5 <- function(DF) {
  DF <- DF %>% select(placement_id, date, impressions,served, kserved=komoona_served) %>% filter(impressions>500, served>40)
  DF$date <- as.Date(DF$date,format="%m/%d/%Y")
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("komoona_served","served","serv_ratio"))
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("impressions","kserved","komoona_fill"))
  DF <- advancePredictionInTimeAllPlacements(DF, key = "placement_id", series=c("smooth_komoona_fill","komoona_fill"))
  DF$predict_served_stage1 <- DF$smooth_fill * DF$impressions
  DF$predict_served_stage2 <- DF$smooth_komoona_fill * DF$komoona_fill_prediction_factor * DF$impressions
  return(DF)

}