library(dplyr)
library(outliers)
library(ggplot2)
p.critical=0.005
minLength=14
loadData <- function() {
  rawDF <- read.csv("lost_imps_by_day.csv")
}

singleOutlierFilter <- function(groupIdentifier,values) {
  vecs <- tapply(values, groupIdentifier, chisq.pvalue)
  subscripts <- tapply(values, groupIdentifier, NULL)
  reconstructed <- numeric(length(subscripts))
  for (i in 1:max(subscripts)) {
    reconstructed[subscripts==i] <- vecs[[i]]
  }
  return (reconstructed)
}


multiOutlierFilter <- function(groupIdentifier,values) {
  repeat {
    numNAEntriesBefore <- sum(is.na(values))
    values <- singleOutlierFilter(groupIdentifier,values)
    numNAEntriesAfter <- sum(is.na(values))
    if (numNAEntriesAfter==numNAEntriesBefore)
      break
  }
  return (values)
}

chisq.pvalue <- function(vec) {
  if (sum(!is.na(vec))<10)
    return (vec)
  a <- chisq.out.test(vec)
  outlierPosition <- match(TRUE, outlier(vec,logical=TRUE))
  if (a$p.value < p.critical)
    vec[outlierPosition]=NA
  return(vec)
}

filterLostOutliers <- function(rawDF) {
  rawDF$rel_lost <- multiOutlierFilter(rawDF$placement_id,rawDF$rel_lost)
  return(rawDF)
}

Analysis.BoxPlot <- function(rawDF) {
  periodLength <- 14
  rawDF <- filterLostOutliers(rawDF)
  rawDF$periodNum <- as.factor(floor(as.numeric(difftime(as.Date(rawDF$date,format="%m/%d/%Y"),as.Date("2015-07-01"),units="days") / periodLength)))
  rawDF <- rawDF %>% filter(placement_id!= "9d5b3ef95e64dc6b252cd1d50e2a579c" & placement_id!= "bab3a2b6c97481906df2ff0051906382" )
  stats <- rawDF %>% group_by(placement_id, periodNum) %>% summarise(m=mean(rel_lost, na.rm=TRUE), s= sd(rel_lost, na.rm=TRUE))
  g <- ggplot(rawDF) + geom_boxplot(aes(x=periodNum, y=rel_lost)) + facet_wrap(~placement_id) + coord_cartesian(ylim = c(-0, 0.2))
  print(g)
}

Analysis.Zscore <- function(rawDF) {
  rawDF <- rawDF %>% arrange(placement_id,as.Date(date,format="%m/%d/%Y"))
  rawDF <- filterLostOutliers(rawDF)
  rawDF$zScore <- zScore(rawDF$placement_id,rawDF$rel_lost)
  rawDF$date <- as.Date(rawDF$date, format="%m/%d/%Y")
  g1 <- ggplot(rawDF) + geom_line(aes(x=date,y=zScore)) + facet_wrap(~placement_id) + coord_cartesian(ylim = c(-2, 2))
  g2 <- ggplot(rawDF) + geom_density(aes(x=zScore), fill="blue") + facet_wrap(~placement_id) + coord_cartesian(xlim = c(-5, 5))
  print(g2)
}

zScore <- function(groupIdentifier,values) {
# this function gives a "z score" to a value based on [minLength] preceding values in timeseries.
  subscripts <- tapply(values, groupIdentifier, NULL)
  reconstructed <- numeric(length(subscripts))
  for (i in 1:max(subscripts)) {
    vec <- values[subscripts==i]
    len <- length(vec)
    z <- numeric(len)
    z <- z*NA
    if (len > minLength) {
      for (d in (minLength+1):len) {
        m <- mean(vec[(d-minLength):(d-1)],na.rm=TRUE)
        t <- sd(vec[(d-minLength):(d-1)],na.rm=TRUE)
        z[d]=(vec[d]-m)/t
      }
    }
    reconstructed[subscripts==i] <- z
  }
  return (reconstructed)
}

