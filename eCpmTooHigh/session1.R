library(dplyr)
library(ggplot2)
readInput <- function() {
  rawDF<-read.csv("C:/Shahar/Projects/eCpmTooHigh/performance_with_fp.out.csv", sep=";", as.is=TRUE)
  rawDF$performance_date <- as.Date(rawDF$performance_date)
  return (rawDF)
}

extractFromChangeColumns <- function(rawDF) {
  floorPriceVec <- extractFloorPriceByDate(rawDF)
  isOptimizedVec <- extractIsOptimizedByDate(rawDF)
  optimGoalVec <- extractOptimizationGoal(rawDF)
  data <- rawDF %>%
    transmute(tagid
              , performance_date
              , impressions
              , fill
              , ecpm
              , floorPrice = floorPriceVec
              , isOptimized = isOptimizedVec
              , optimizationGoal = optimGoalVec
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

  data2 <- subset(data,meaningfulImpressions & meaningfulFloorPrice & !is.na(optimizationGoal))
  ggplot()+geom_histogram(data=data2,aes(x=ecpmSlack, fill=optimizationGoal), binwidth=0.15, alpha=0.5) +
    xlim(-0.2,1)#


}

