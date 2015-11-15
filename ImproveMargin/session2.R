currdir = 'C:/Shahar/Projects/ImproveMargin/'
source('C:/Shahar/Projects/libraries.R')


runSession2 <- function() {
  rawDF <- read.csv(paste0(currdir, "performance_nov_6_12.csv"))
  groupDF <- aggregateOverDates(rawDF)
  filteredDF <- groupDF %>% filter(fill<0.15 & margin < 0.2 & currentGoal %in% c("B","C","C-"))
  write.csv(filteredDF,"TypeGCandidates.csv")
  return(filteredDF)
}


aggregateOverDates <- function(rawDF) {
 rawDF <- rawDF %>%
    rename(placement_id=tagid) %>%
    mutate(served=impressions*fill/100,
           max_profit=(total_ecpm-floor_price)*served/1000)


  # group by placement_id - sum over dates
  groupDF <- rawDF %>%
    group_by(placement_id,username,sitename) %>%
    summarise(impressions=sum(impressions),
              served=sum(served),
              cost=sum(cost),
              profit=sum(profit),
              max_profit=sum(max_profit)) %>%
    mutate(fill=served/impressions,
           revenue=cost+profit,
           margin = profit/revenue,
           max_margin=max_profit/revenue)  %>%
    ungroup()
  currentGoal <- rawDF %>% group_by(placement_id) %>%
    summarise( current_goal=tail(optimization_goal,n=1)) %>%
    ungroup()
  groupDF <- left_join(groupDF, currentGoal)

  return(groupDF)
}
