source('C:/Shahar/Projects/LostImpressions/session2.R')

runMain <- function(DF=data.frame()) {
  if(nrow(DF)==0) #not input
    DF <- main("lost_imps_by_day.csv", "pred_lost.csv", "placement_id", "rel_lost", "pred_lost","lag_lost", "pred_err",W=14)
  DF <- addComparisonColumns(DF)
  histogramPlots(DF)
}

addComparisonColumns <- function(DF) {
  DF <- DF %>% filter(impressions >1000) %>%
      mutate(pred_served = komoona_served/(1-pred_lost),
             pred_fill = pred_served/impressions,
             pred_error = pred_fill - rel_fill,
             ref_served = komoona_served, #/(1-lag_lost),
             ref_fill = ref_served/impressions,
             ref_error = ref_fill - rel_fill)
  return(DF)
}

histogramPlots <- function(DF) {
 p <- ggplot(DF) +
      geom_density(aes(x=ref_error,y=..scaled..),fill="red",na.rm=TRUE, alpha=0.5) +
     geom_density(aes(x=pred_error,y=..scaled..),fill="blue",na.rm=TRUE, alpha=0.5) +
     geom_vline(xintercept=0, colour="black")+
     facet_wrap(~placement_id)+coord_cartesian(xlim=c(-0.5,0.5))
 print (p)
}


