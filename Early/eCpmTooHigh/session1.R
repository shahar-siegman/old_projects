library(dplyr)
library(ggplot2)
readInput <- function() {
  rawDF<-read.csv("C:/Shahar/Projects/eCpmTooHigh/performance_with_fp_oct.out.csv", sep=";", as.is=TRUE)
  rawDF$performance_date <- as.Date(rawDF$performance_date)
  return (rawDF)
}

extractFromChangeColumns <- function(rawDF) {
  floorPriceVec <- extractFloorPriceByDate(rawDF)
  isOptimizedVec <- extractIsOptimizedByDate(rawDF)
  optimGoalVec <- extractOptimizationGoal(rawDF)
  riskVec <- extractRiskByDate(rawDF)
  data <- rawDF %>%
    transmute(tagid
              , performance_date
              , impressions
              , fill
              , ecpm
              , floorPrice = floorPriceVec
              , isOptimized = isOptimizedVec
              , optimizationGoal = optimGoalVec
              , riskPercent = riskVec
              , ecpmSlack = ecpm-floorPrice
              , cost
              , meaningfulFloorPrice = floorPrice > 0.15
              , meaningfulImpressions = impressions > 2000) %>%
    filter(!is.na(isOptimized) & !is.na(floorPrice))
  return (data)
}

extractFloorPriceByDate <- function (rawDF) {
  nr <- nrow(rawDF)
  floorPriceVec <- numeric(nr)
  for (i in 1:nr) {
    floorPriceVec[i] <- getValueByDate(rawDF$performance_date[i], rawDF$floor_prices[i], rawDF$floor_change_dates[i])
  }
return (floorPriceVec)
}

extractIsOptimizedByDate <- function (rawDF) {
  nr <- nrow(rawDF)
  isOptimizedVec <- numeric(nr)
  for (i in 1:nr) {
    isOptimizedVec[i] <- getValueByDate(rawDF$performance_date[i], rawDF$optimization_in_out[i], rawDF$in_out_date[i])
  }
  return (isOptimizedVec)
}

extractOptimizationGoal <- function (rawDF) {
  nr <- nrow(rawDF)
  OptimGoalVec <- character(nr)
  for (i in 1:nr) {
    OptimGoalVec[i] <- getValueByDate(rawDF$performance_date[i], rawDF$optimization_goal[i], rawDF$goal_change_date[i], as.character)
  }
  return (OptimGoalVec)
}

extractRiskByDate <- function (rawDF) {
  nr <- nrow(rawDF)
  riskVec <- numeric(nr)
  for (i in 1:nr) {
    riskVec[i] <- getValueByDate(rawDF$performance_date[i], rawDF$risk_percent[i], rawDF$risk_change_date[i])
  }
  return(riskVec)
}

getValueByDate <- function(date, valueList, changeDates, as.type=as.numeric, initialValue=NA, filterChangeDay=TRUE) {
  changeDateVec <- as.Date(strsplit(changeDates, ",")[[1]])
  diffDays <- changeDateVec - date
  interval <- findInterval(0,diffDays)
  valueVec <- as.type(strsplit(valueList,",")[[1]])
  isChangeDay <- sum(diffDays==0) > 0
  if (isChangeDay && filterChangeDay)
    value <-  NA
  else if (interval==0)
    value <- initialValue
  else value <- valueVec[interval]
  return (value)
}

plots <- function(data) {
  data1 <- data[data$meaningfulImpressions,]
  ggplot()+geom_histogram(data=data1,aes(x=ecpmSlack, y=..count../sum(..count..), fill=meaningfulFloorPrice), binwidth=0.125) #

  data2 <- subset(data,meaningfulImpressions & meaningfulFloorPrice & !is.na(optimizationGoal) & isOptimized==1)
  ggplot()+geom_histogram(data=data2,aes(x=ecpmSlack, fill=optimizationGoal), binwidth=0.15, alpha=0.5) +
    xlim(-0.2,1)#
  g <- unique(data2$optimizationGoal)
  for (i in 1:length(g)) {
    print (g[i])
    print (quantile(unlist(data2 %>% filter(optimizationGoal==g[i]) %>% select(ecpmSlack)), probs=seq(0.1, 1, 0.1) ))
  }

  r1 <- data %>% group_by(optimizationGoal, riskPercent) %>% summarise(count=n(),medianSlack = median(ecpmSlack)) %>% filter(count>50)
  ggplot(data=r1)+geom_bar(aes(x=riskPercent,y=medianSlack),stat="identity",position="dodge",fill="blue")+facet_wrap(~optimizationGoal)

  t1 <- dat %>% filter(optimizationGoal=="A+")
  ggplot(data=t1 %>% filter(!is.na(riskPercent)))+geom_density(aes(x=ecpmSlack,color=as.factor(riskPercent)))
}

