currdir = 'C:/Shahar/Projects/ImproveMargin/'
source('C:/Shahar/Projects/libraries.R')
source(paste0(currdir,'session2.R'))



runSession3 <- function() {
  rawDF <- read.csv(paste0(currdir, "performance_nov_6_12.csv"))
  groupDF <- aggregateOverDates(rawDF)
  groupDF <- groupDF %>% filter(profit>=0, max_profit>0, !current_goal=="")
  maxMargins <- groupDF %>%
    group_by(current_goal) %>%
    arrange(desc(max_margin)) %>%
    mutate(desc_rev = cumsum(revenue)) %>%
    arrange(max_margin) %>%
    mutate(inc_rev = cumsum(revenue),
           inc_profit = cumsum(max_profit),
           sim_profit=max_margin*desc_rev+inc_profit,
           cum_margin = sim_profit/(desc_rev+inc_rev))

  p1 <- ggplot(maxMargins) +
    geom_line(aes(x=max_margin,y=cum_margin)) +
    facet_wrap(~current_goal)

  #print(p1 + coord_cartesian(xlim=c(0,1),ylim=c(0,1)))
  print(p1 + coord_cartesian(xlim=c(0,0.3),ylim=c(0,0.3)))
  return(groupDF)
  }
