library(dplyr)
library(ggplot2)
getRawPlacementData <- function() {
  rawDF<-read.csv("C:/Shahar/Projects/Discrepancy/raw_input/data.txt")
  rawDF$Date <- as.Date(rawDF$Date,format="%d/%m/%Y")
  return(rawDF)
}

dByPercentileByLength <- function() {
  # each row: a particular chain length
  # each column: different category
  return (matrix(data=c(0.02217738, 0, 0, 0.033033396, 0.040871774,
                        0.037390663, 0.051550697, 0.056261989, 0.070640604, 0.064655012,
                        0.046207342, 0.069245461, 0.072188022, 0.081182855, 0.100386763,
                        0.058091496, 0.08646321, 0.101190576, 0.13439563, 0.116811584,
                        0.075231413, 0.094521006, 0.118095289, 0.135233429, 0.128805942,
                        0.075334121, 0.101153874, 0.12951405, 0.137355021, 0.156126689,
                        0.080398846, 0.118872192, 0.133850714, 0.162576372, 0.172941469,
                        0.09277559, 0.120612949, 0.14654267, 0.176608815, 0.197229507,
                        0.094847915, 0.137898533, 0.185141754, 0.209088007, 0.232806957,
                        0.116629786, 0.172786727, 0.208996453, 0.236350137, 0.271494936,
                        0.129129403, 0.182388126, 0.228793711, 0.28245799, 0.283195773,
                        0.176345442, 0.231528173, 0.303243233, 0.35616288, 0.381108087,
                        0.268501886, 0.322640367, 0.391877968, 0.467791911, 0.503797605,
                        0.532425846, 0.548081114, 0.899516676, 0.843405534, 0.902956858),nrow=5,byrow=FALSE))
}

fitAlongChainLength <- function (dByPercentileByLengthData) {
  # output a linear model (by chain length) per category
  R=nrow(dByPercentileByLengthData) # 5
  C=ncol(dByPercentileByLengthData) # 14
  d1<-data.frame(y=dByPercentileByLengthData[,1],x=seq(1,R))
  fit1 <- lm(y~x, data=d1)
  b=coefficients(fit1)
  for (i in 2:C) {
    d1<-data.frame(y=dByPercentileByLengthData[,i],x=seq(1,R))
    fit1 <- lm(y~x, data=d1)
    a <- coefficients(fit1) # intercept coeff, linear coeff
    b=rbind(b, a)
  }
  return(b)
}

fitAlongPercentiles <- function(b) {
  # fit an exponential model to the intercepts and to the linear coefficients
  # of the individual category models
  C=nrow(b)
  ptiles=1:C/C- 1/(2*C)
  d2 <- data.frame(intercept=b[,1],linear=b[,2], x=ptiles)
  fitIntercept <- lm(log(intercept) ~ x, data=d2)
  fitLinear <- lm(log(linear) ~ x, data=d2)
  return(rbind(coefficients(fitIntercept),coefficients(fitLinear)))
}

filterAndGroupRawData <- function (df, startDate, endDate) {
  # aggregate data for a certain date range by placement and chain length
  res <- df %>%
    filter(Date >= startDate & Date < endDate) %>%
    group_by(placementId,ChainLength) %>%
    select(Impressions,Served,House) %>%
    summarise(
      sumImps=sum(Impressions),
      sumServed=sum(Served),
      sumHouse=sum(House)) %>%
    filter(sumImps>100,sumServed>5)
  res$DiscrepancyPercent=(res$sumImps-res$sumServed-res$sumHouse)/res$sumImps
  return(res)
}

getDiscrepancyModel <- function(groupedDF) {
  # get the model of each placement-length
  d<-dByPercentileByLength()
  C=ncol(d)+1
  dr=nrow(d)
  t <- fitAlongPercentiles(fitAlongChainLength(d))
  nLines=nrow(groupedDF)

  newVec <- vector(length=nLines)
  interval <- newVec
  percentile <- newVec
  interceptForCLModel <- newVec
  slopeForCLModel <- newVec

  for (i in 1:nLines) {
    # lookup the current DiscrepancyPercent in d in the row matching the chain length
    currentChainLength=min(groupedDF$ChainLength[i],dr)
    currentDiscrepancy=groupedDF$DiscrepancyPercent[i]
    interval[i]=findInterval(currentDiscrepancy, d[currentChainLength,])
    percentile[i]=interval[i]/C+1/(2*C)
    interceptForCLModel[i]=exp(t[1,1]+t[1,2]*percentile[i])
    slopeForCLModel[i]=exp(t[2,1]+t[2,2]*percentile[i])
  }
  groupedDF$interval <- interval
  groupedDF$percentile <- percentile
  groupedDF$intercept <- interceptForCLModel
  groupedDF$slope <- slopeForCLModel
  return(groupedDF)
}

getSamplePlacementData <- function (rawDF) {
  filterAndGroupRawData(rawDF,"2015-07-01","2015-07-08")
}

getTestPlacementData <- function(rawDF) {
  filterAndGroupRawData(rawDF,"2015-07-09","2015-07-23")
}

averagePlacmentModel <- function(groupedDF) {
  placementModelDF <- groupedDF %>%
    group_by(placementId) %>%
    select(intercept,slope) %>%
      summarise(interceptForCLModel=mean(intercept),
                slopeForCLModel=mean(slope))
}

perdictUsingPlacementModel <- function(groupedDF,placementModelDF) {
  nLines <- nrow(groupedDF)
  predicted <- vector(length=nLines)
  for (i in 1:nLines) {
  #for (i in 1:50) {
    currentPId <- groupedDF$placementId[i]
    currentChainLength <- groupedDF$ChainLength[i]
    pos=which(placementModelDF$placementId==currentPId)
    # assert(length(pos)==1)
    # print(paste(c("i=",i,"; Current PID: ",currentPId,"; matching position: ", pos),collapse=""))
    if (identical(pos,integer(0))) {
      # leave blank (NA)
      # predicted[i]<-0
    } else {
      intercept <- placementModelDF$intercept[pos]
      slope <- placementModelDF$slope[pos]
      predicted [i] <- intercept + slope*currentChainLength
    }
  }

  groupedDF$predicted <- predicted
  return(groupedDF)
}

mainPredict <- function(rawDF=data.frame()) {
  if (identical(rawDF,data.frame()))
    rawDF <- getRawPlacementData()
  sampleDF <- getSamplePlacementData(rawDF)
  discrepancyModel <- averagePlacmentModel(getDiscrepancyModel(sampleDF))
  testDF <- getTestPlacementData(rawDF)
  predictionDF <- perdictUsingPlacementModel(testDF, discrepancyModel)
}

mainPlot <- function(predictionDF=data.frame()) {
  if (identical(predictionDF,data.frame()))
    predictionDF <- mainPredict()
  write.table(predictionDF, file="predict_result.csv",sep=",",col.names=NA)
  f <- predictionDF %>% filter(DiscrepancyPercent>0)
  print(ggplot()+geom_point(data=f,aes(x=predicted,y=DiscrepancyPercent)))
  return(predictionDF)

}
