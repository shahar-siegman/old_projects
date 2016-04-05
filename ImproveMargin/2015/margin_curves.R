runMarginCurve <- function() {
  rawDF <- read.csv("performance_nov_7_13.csv")

  a <- marginFromPerformanceSheet(rawDF)
  drawDF <- a[[1]]
  p1 <- ggplot(drawDF,aes(x=nominal_margin,y=effective_margin,group=goal_type,color=goal_type)) +
    geom_line() +
    geom_point()

  print(p1)

  reportDF <- a[[3]] %>% select(placement_id, sitename, goal_type, impressions, served, cost, profit, revenue, floor_price, ecpm,
                                current_revshare)
    #select(-max_profit, -max_margin, -group_revenue, maxxed_margin, cumulative_revenue)

  write.csv(a[[2]],"groupdf.csv")
  write.csv(reportDF,"reportdf.csv")

  return(a)
}

marginFromPerformanceSheet <- function(rawDF) {
  # 1. arrange
  rawDF <- rawDF %>%
    rename(placement_id=tagid,
           goal_type = latest_optimization_goal ) %>%
    mutate(max_profit=(total_ecpm-floor_price)*served/1000)

  # 2. sum by dates

  groupDF <- rawDF %>%
    group_by(placement_id,sitename,goal_type) %>%
    summarise(impressions=sum(impressions),
              served=sum(served),
              cost=sum(cost),
              profit=sum(profit),
              revenue=sum(revenue),
              max_profit=sum(max_profit),
              floor_price=tail(latest_floor_price,1),
              ecpm = tail(total_ecpm,1),
              current_revshare=tail(revshare,1)) %>%
    ungroup()

  # max margin per placement
  groupDF <- groupDF %>%
    mutate(max_margin=max_profit/revenue) %>%
    filter(profit>=0, max_profit>0) %>%
    arrange(goal_type,max_margin)

  # total revenue by goal type
  revByGoalType <- groupDF %>%
    group_by(goal_type) %>%
    summarise(group_revenue=sum(revenue))

  # join rev by goal type
  groupDF <- inner_join(groupDF, revByGoalType)

  # cumulative revenue by goal type
  groupDF <- groupDF %>% group_by(goal_type)  %>%
    mutate(maxxed_profit = cumsum(max_profit),
           cumulative_revenue = cumsum(revenue),
           unmaxxed_profit =  (group_revenue-cumulative_revenue)*max_margin,
           profit_at_margin = maxxed_profit + unmaxxed_profit) %>%
    ungroup()

  # clean up
  finalData <- groupDF %>% select(goal_type, max_margin, profit_at_margin, group_revenue) %>%
    rename(nominal_margin=max_margin) %>%
    mutate(effective_margin = profit_at_margin / group_revenue)

  fixIncrement <- ddply(finalData,"goal_type",my_approx)

  return(list(fixIncrement, finalData, groupDF, revByGoalType))
}

my_approx <- function(df) {
  xout <- seq(0,1, length.out=101)
  return(data.frame(goal_type=df$goal_type[1], nominal_margin=xout,
                    effective_margin= approx(df$nominal_margin,df$effective_margin,xout)[[2]],
                    profit_at_margin = approx(df$nominal_margin, df$profit_at_margin, xout)[[2]]
                    ))
}
