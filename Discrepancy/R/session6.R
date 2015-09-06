library(dplyr)
groupedAnalysis <- function(rawDF) {
  period1 <- filterAndGroupRawData(rawDF,"2015-07-01","2015-07-08")
  period2 <- filterAndGroupRawData(rawDF,"2015-07-09","2015-07-23")
  period1$DiscrepancyFactor=as.factor(round(period1$DiscrepancyPercent/2,2)*2)
  period2$DiscrepancyFactor=as.factor(round(period2$DiscrepancyPercent/2,2)*2)
  p[[1]]<-ggplot(data=period1,aes(x=DiscrepancyPercent, fill=as.factor(ChainLength))) + geom_density(alpha=0.25)+xlim(-0.5,1)+ylim(0,11)
  p[[2]]<-ggplot(data=period2,aes(x=DiscrepancyPercent, fill=as.factor(ChainLength))) + geom_density(alpha=0.25)+xlim(-0.5,1)+ylim(0,11)
  lapply(p,print)
  return(p)
}

discrepancyCumlativeDistrib <- function(periodDF) {
  p<-periodDF %>%
    group_by(ChainLength) %>%
    mutate(DiscCDF =cume_dist(DiscrepancyPercent),
           DiscRank=min_rank(DiscrepancyPercent))
    #write.csv(p,"check_rank.csv")
  return(p)
}
### ******************************************
#   createPredictionSpreadsheet
#   main function for prediction and comparison
### ******************************************
createPredictionSpreadsheet <- function(period1,period2) {
  # join the "
  period1 <- discrepancyCumlativeDistrib(period1)

  joined <- period2 %>%
    select(placementId,ChainLength,DiscrepancyPercentPeriod2=DiscrepancyPercent) %>%
    left_join(period1 %>% select (placementId,ChainLength,DiscrepancyPercentPeriod1=DiscrepancyPercent), by=c("placementId","ChainLength"))

  discrepancyModelPerPlacement <- averagePlacmentModel(getDiscrepancyModel(period1))

  joined <- joined %>% left_join(discrepancyModelPerPlacement, by="placementId")

  joined$linearPred=joined$interceptForCLModel+joined$slopeForCLModel*joined$ChainLength
  medianDF <- data.frame(ChainLength=1:5,medianCLDiscrepancy=dByPercentileByLength2(period1,5,1))

  joined <- joined %>% left_join(medianDF, by="ChainLength")
  return(joined)
}

dByPercentileByLength2 <- function(periodDataWithCDF, maxCL, nDistribPoints) {
  requestedProbabilityPoints=equallySpacedBetween0And1(nDistribPoints)
  a=matrix(NA,maxCL,nDistribPoints)
  for (cl in 1:maxCL) {
    dataForCL <- periodDataWithCDF %>%
      select(DiscCDF,DiscrepancyPercent) %>%
      filter(ChainLength==cl) %>% arrange(DiscCDF)

    ind<-findInterval(requestedProbabilityPoints,dataForCL$DiscCDF)
    a[cl,] <- dataForCL$DiscrepancyPercent[ind]
  }
  return(a)
}


testDByPercentileByLength2 <- function(rawDF=data.frame()) {
  if (identical(rawDF,data.frame()))
    rawDF <- getRawPlacementData()
  period1 <- discrepancyCumlativeDistrib(getSamplePlacementData(rawDF))
  dByPercentileByLength2(period1,5,14)

}
