library(dplyr)
readInput <- function() {
  rawDF<-read.csv("C:/Shahar/Projects/eCpmTooHigh/performance_with_fp.out.csv", sep=";", as.is=TRUE)
  rawDF$performance_date <- as.Date(rawDF$performance_date)
  return (rawDF)
}

addFloorPriceColumn <- function (rawDF) {
  nr <- nrow(rawDF)
  floorPrice <- numeric(nr)
  for (i in 1:nr) {
    floorPrice[i] <- getFloorPriceByDate(rawDF$performance_date[i], rawDF$floor_prices[i], rawDF$floor_change_dates[i])
  }

  rawDF$floorPrice <- floorPrice
  #rawDF$ecpmRatio <- rawDF$ecpm/ rawDF$floorPrice
  data <- rawDF %>%
    transmute(tagid
              , performance_date
              , impressions
              , fill
              , ecpm
              , floorPrice
              , ecpmRatio=ecpm/floorPrice
              , cost)
  return (data)
}

getFloorPriceByDate <- function(date, floorPriceList, ChangeDates) {
  changeDateVec <- as.Date(strsplit(ChangeDates, ",")[[1]])
  diffDays <- changeDateVec - date
  interval <- findInterval(0,diffDays)
  floorPriceVec <- as.numeric(strsplit(floorPriceList,",")[[1]])
  if (interval>0 && sum(diffDays==0)==0)
    return (floorPriceVec[interval])
  else
    return (-1)
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

plotRatioDensity <- function(data) {
  data <- data[data$floorPrice>0,]
  ggplot()+geom_density(data=data,aes(x=ecpmRatio,weight=cost/sum(cost)))
}

