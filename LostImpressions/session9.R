currdir = 'C:/Shahar/Projects/LostImpressions/'
source('C:/Shahar/Projects/libraries.R')
source(paste0(currdir,'session4.R'))

runSession9 <- function() {
  rawDF <- read.csv(paste0(currdir,'mysql_redshift_joined.csv'))
  # the below 3 placements were prefiltered
  # rawDF <- rawDF %>% filter(!(placement_id %in% c("203047dd1929e08684f45771d064466c", "5af6afe59f7bbb77b82fff5d388f8073" ,"cd78514b72055715be33a8812d38def6")))
  rawDF <- rawDF %>% rename(date=date_joined) %>%
    mutate(is_mobile_chain =
             ifelse(mobile_imps+desktop_imps<30,"unknown",
                    ifelse(mobile_imps>15*desktop_imps,"mobile","global")))
  # session9PlacementAnalysis(rawDF)
  # time to look at the ratio at the individual chain level
  rawDF <- rawDF %>% mutate(komoona_imps=desktop_imps+mobile_imps+unknown_imps,
                            komoona_served=desktop_served+mobile_served+unknown_served)
  a <- session9ChainAnalysis(rawDF)
  return(a)
}

session9PlacementAnalysis <- function(rawDF) {
  DFWS <- rawDF %>% groupByPlacementDate()
  DFWS <- DFWS %>% mutate(komoona_imps=desktop_imps+mobile_imps+unknown_imps,
                          komoona_served=desktop_served+mobile_served+unknown_served)
  #session9PlacementPlots(DFWS)

  DFNS <- rawDF %>% filter(non_smaato_chain=="Y") %>% groupByPlacementDate()
  DFNS <- DFNS %>% mutate(komoona_imps=desktop_imps+mobile_imps+unknown_imps,
                          komoona_served=desktop_served+mobile_served+unknown_served)
  session9PlacementPlots(DFNS)
  #return(DFWS)

  # minor differences in this respect between with and without smaato.

}

session9PlacementPlots <- function(DF) {
  # going back to long-duration metrics. let's first see how the moving averages behave over the course of the available data
# our data is now at the chain level, so let's review it at placement level, with mobile separated from non-mobile
  # and let

  # first redraw the graphs of session8
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id"), series=c("imps","served","fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id"), series=c("komoona_imps","komoona_served","komoona_fill"))
  DF$komoona_fill_factor <- DF$smooth_fill/DF$smooth_komoona_fill
  pp1 <- session8Plot1(DF)
  print(pp1)
  }

groupByPlacementDate <- function(DF) {
  DF %>%  group_by(placement_id,date) %>%
    summarise(imps=sum(imps,na.rm=T), served=sum(served,na.rm=T),
              desktop_imps=sum(desktop_imps,na.rm=T), desktop_served=sum(desktop_served,na.rm=T),
              mobile_imps=sum(mobile_imps,na.rm=T), mobile_served=sum(mobile_served,na.rm=T),
              unknown_imps=sum(unknown_imps,na.rm=T), unknown_served=sum(unknown_served,na.rm=T))
  return(DF)
}

session9ChainAnalysis <- function(DF) {
  DF <- DF %>% filter(served>50)
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","chain_no_fps"), series=c("komoona_imps","mobile_served","mobile_impshare"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","chain_no_fps"), series=c("komoona_imps","komoona_served","komoona_fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","chain_no_fps"), series=c("imps","served","fill"))
  DF$fill_factor <- DF$smooth_komoona_fill / DF$smooth_fill

  pc1 <- ggplot(DF) + geom_point(aes(x=smooth_mobile_impshare,y=fill_factor,color=chain_no_fps)) + facet_wrap(~placement_id)
  print(pc1)
  return(DF)
}