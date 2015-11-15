currdir = 'C:/Shahar/Projects/LostImpressions/'
source('C:/Shahar/Projects/libraries.R')
source(paste0(currdir,'session4.R'))

runSession9 <- function() {
  rawDF <- read.csv(paste0(currdir,'mysql_redshift_joined.csv'))
  # the below 3 placements were prefiltered:
  # c("203047dd1929e08684f45771d064466c", "5af6afe59f7bbb77b82fff5d388f8073" ,"cd78514b72055715be33a8812d38def6")
  rawDF <- rawDF %>% rename(date=date_joined) %>%
    mutate(is_mobile_chain =
             ifelse(mobile_imps+desktop_imps<30,"unknown",
                    ifelse(mobile_imps>15*desktop_imps,"mobile","global")))
  # data sanity - show komoona factor on desktop and mobile separately, at placement level, like in session8
  session9Sanity(rawDF, T)

  rawDF[is.na(rawDF)] <- 0
  # time to look at the ratio at the individual chain level
  rawDF <- rawDF %>% mutate(komoona_imps=desktop_imps+mobile_imps+unknown_imps,
                            komoona_served=desktop_served+mobile_served+unknown_served)
  a <- session9ChainAnalysis(rawDF, F)
  return(a)
}

session9Sanity <- function(rawDF, includeProblemNetworks = T) {
  if (!includeProblemNetworks)
    rawDF <- rawDF %>% filter(chain_no_z_j=="Y")

  DF <- rawDF %>% groupByPlacementDate()
  DF <- DF %>% mutate(komoona_imps=desktop_imps+mobile_imps+unknown_imps,
                          komoona_served=desktop_served+mobile_served+unknown_served)

  session9SanityPlots(DF)
  return(DF)
  # the same more-or-less steady curves, only minor differences between with and without smaato.
}

session9SanityPlots <- function(DF) {
  # for long-duration metrics, let's revalidate how the moving averages behave over the course of the available data
  # Reviewing at placement level, comparing mobile vs. non-mobile
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id"), series=c("imps","served","fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id"), series=c("komoona_imps","komoona_served","komoona_fill"))
  DF$komoona_fill_factor <- DF$smooth_fill/DF$smooth_komoona_fill
  # reuse the graph of session8
  pp1 <- session8Plot1(DF)
  # print(pp1)
  }

groupByPlacementDate <- function(DF) {
  DF %>%  group_by(placement_id,date) %>%
    summarise(imps=sum(imps,na.rm=T), served=sum(served,na.rm=T),
              desktop_imps=sum(desktop_imps,na.rm=T), desktop_served=sum(desktop_served,na.rm=T),
              mobile_imps=sum(mobile_imps,na.rm=T), mobile_served=sum(mobile_served,na.rm=T),
              unknown_imps=sum(unknown_imps,na.rm=T), unknown_served=sum(unknown_served,na.rm=T))
  return(DF)
}

session9ChainAnalysis <- function(DF, includeProblemNetworks = T) {
  #DF <- DF %>% filter(served>50)
  if (!includeProblemNetworks)
    DF <- DF %>% filter(chain_no_z_j=="Y")

  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","chain_no_fps"), series=c("komoona_imps","mobile_served","mobile_impshare"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","chain_no_fps"), series=c("komoona_imps","komoona_served","komoona_fill"))
  DF <- learnHistoricalRateAllPlacements(DF, key = c("placement_id","chain_no_fps"), series=c("imps","served","fill"))
  DF$fill_factor <- DF$smooth_komoona_fill / DF$smooth_fill

  # filter low-volume chains
  lowVolChains <- DF %>%
    group_by(placement_id,chain_no_fps) %>%
    summarise(imps=sum(komoona_imps),served=sum(komoona_served)) %>%
    filter(imps < 300, served<40) %>%
    select(placement_id, chain_no_fps) %>% mutate(vol="low")

  DF <- left_join(DF, lowVolChains) %>% filter(is.na(vol)) %>% select(-vol)


  p1 <- ggplot(DF) + geom_point(aes(x=smooth_mobile_impshare,y=fill_factor,color=chain_no_fps)) + facet_wrap(~placement_id) +
    coord_cartesian(ylim=c(0,3))
  print(p1)
  return(DF)
}