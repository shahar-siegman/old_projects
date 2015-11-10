currdir = 'C:/Shahar/Projects/LostImpressions/'
source('C:/Shahar/Projects/libraries.R')
source(paste0(currdir,'session4.R'))

runSession8 <- function() {
  rawDF <- read.csv(paste0(currdir,'experiment_data_aggregated.csv'))
  rawDF <- rawDF %>% filter(!(placement_id %in% c("203047dd1929e08684f45771d064466c", "5af6afe59f7bbb77b82fff5d388f8073" ,"cd78514b72055715be33a8812d38def6")))
  a <- session8Plots(rawDF)
  return(a)
}


session8Plots <- function(DF) {
  # going back to long-duration metrics. let's first see how the moving averages behave over the course of the available data
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("true_global_imps","true_global_served","fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("nd_kimpressions","nd_kserved","komoona_fill"))
  DF$komoona_fill_factor <- DF$smooth_fill/DF$smooth_komoona_fill

  p1 <- ggplot(DF) +
    geom_line(aes(x=date,y=smooth_fill, group=placement_id, color=placement_id)) +
    geom_line(aes(x=date,y=smooth_komoona_fill, group=placement_id, color=placement_id)) +
    geom_point(aes(x=date,y=smooth_komoona_fill, group=placement_id, color=placement_id))
  # indeed, moving averages vary rather slowly and the ratios seem to behave. to capture the point, let's
  # plot the daily ratio and the smoothed ratio

  DF <- DF %>% mutate(fill = true_global_served / true_global_imps,
                      komoona_fill = nd_kserved / nd_kimpressions,
                      komoona_fill_factor_daily  = komoona_fill / fill,
                      komoona_fill_factor_smooth = smooth_komoona_fill / smooth_fill)
  p2 <- ggplot(DF) +
    geom_line(aes(x=date,y=komoona_fill_factor_daily, group=placement_id, color=placement_id)) +
    geom_line(aes(x=date,y=komoona_fill_factor_smooth, group=placement_id, color=placement_id)) +
    geom_point(aes(x=date,y=komoona_fill_factor_smooth, group=placement_id, color=placement_id)) +
    coord_cartesian(ylim=c(0,1.5))

  # this plot just stresses the point that daily values are junk, long term values are meaningful.
  # now lets look at long term values for mobile

  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("true_mobile_imps","true_mobile_served","mobile_fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = "placement_id", series=c("mobile_kimpressions","mobile_kserved","mobile_kfill"))

  p3 <- ggplot(DF) +
    geom_line(aes(x=date,y=smooth_mobile_fill, group=placement_id, color=placement_id)) +
    geom_line(aes(x=date,y=smooth_mobile_kfill, group=placement_id, color=placement_id)) +
    geom_point(aes(x=date,y=smooth_mobile_kfill, group=placement_id, color=placement_id))
  # looks promising. some more variation. let's review the ratios

  DF$mobile_komoona_fill_factor <- DF$smooth_mobile_kfill / DF$smooth_mobile_fill
  p4 <- ggplot(DF) +
    geom_line(aes(x=date,y=mobile_komoona_fill_factor, group=placement_id, color=placement_id)) +
    geom_line(aes(x=date,y=komoona_fill_factor_smooth, group=placement_id, color=placement_id)) +
    geom_point(aes(x=date,y=komoona_fill_factor_smooth, group=placement_id, color=placement_id))

  # this shows that the mobile factor is not the same as the global one. also the mobile factors seem to be more noisy.
  # the next step is to check if the mobile share of the placements, at the daily level or aggregated over the period,
  # explains the factor factor.
  print(p4)
  return(DF)
}