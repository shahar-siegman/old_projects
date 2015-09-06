mainAnalysisFlow <- function(rawDF = NA, placementSample=NA, externalDiscrepancyData=NA) {
  # get the raw data, if not supplied as input
  if (identical(rawDF, NA))
    rawDF <- getRawPlacementData()

  # aggregate the raw data into sample and test periods
  period1 <- getSamplePlacementData(rawDF)
  period2 <- getTestPlacementData(rawDF)


  # if DF with placements to sample was given, use it
  if (!identical(placementSample,NA) && "placementId" %in% names(placementSample)) {
    print (paste("Sampling",nrow(placementSample), "placements from a total of", nrow (period2)))
    period2 <- period2 %>% inner_join(placementSample %>% select(placementId))
  }
  pred <- createPredictionSpreadsheet(period1, period2)

  if (!identical(externalDiscrepancyData,NA) && "placementId" %in% names(externalDiscrepancyData)) {
    pred <- pred %>% left_join(externalDiscrepancyData, by=c("placementId","ChainLength"))
  }
  return(pred)
}


getPlacementSample <- function() {
  inputDF <- read.csv("C:/Code/Service/Komoona.BigD.NetworkModelUtil/bin/Debug/pcmnts1.txt", header=FALSE)
  inputDF <- inputDF %>% transmute(placementID=V1)
}


analyzePredictionSpreadsheet <- function(pred) {
  pred$granularPrediction <- ifelse(!is.na(pred$DiscrepancyPercentPeriod1), pred$DiscrepancyPercentPeriod1,
                                    ifelse(!is.na(pred$linearPred),pred$linearPred,j$medianCLDiscrepancy))
  pred$Residual <- pred$granularPrediction - pred$DiscrepancyPercentPeriod2
  pred$ProductionResidual <- pred$ProductionModelDiscrepancy - pred$DiscrepancyPercentPeriod2
#  pred$absErr <- abs(pred$Residual)
#  pred$relAbsErr <- pred$absErr/pred$DiscrepancyPercentPeriod2

  predm <- melt(pred,id.vars=c("placementId","ChainLength"),measure.vars = c("DiscrepancyPercentPeriod2","DiscrepancyPercentPeriod1","Residual","ProductionResidual"))
  return(predm)
}

plotResiduals <- function(predm) {
  p<-ggplot(data=predm,aes(x=value, color=variable)) + geom_density() + facet_wrap(~ChainLength)
}

