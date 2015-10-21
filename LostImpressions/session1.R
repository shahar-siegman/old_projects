library(dplyr)
library(outliers)
library(ggplot2)
p.critical=0.005
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


mainAnalysis <- function(rawDF) {
  periodLength <- 14
  rawDF$rel_lost <- multiOutlierFilter(rawDF$placement_id,rawDF$rel_lost)
  rawDF$periodNum <- as.factor(floor(as.numeric(difftime(as.Date(rawDF$date,format="%m/%d/%Y"),as.Date("2015-07-01"),units="days") / periodLength)))
  rawDF <- rawDF %>% filter(placement_id!= "9d5b3ef95e64dc6b252cd1d50e2a579c" & placement_id!= "bab3a2b6c97481906df2ff0051906382" )
  stats <- rawDF %>% group_by(placement_id, periodNum) %>% summarise(m=mean(rel_lost, na.rm=TRUE), s= sd(rel_lost, na.rm=TRUE))
  g <- ggplot(rawDF) + geom_boxplot(aes(x=periodNum, y=rel_lost)) + facet_wrap(~placement_id) + coord_cartesian(ylim = c(-0.1, 0.5))
  print(g)
}
