dByPercentileByLength <- function() {
  return (matrix(data=c(0.02217738,  0, 0, 0.033033396, 0.040871774,
                0.037390663, 0.051550697, 0.056261989, 0.070640604, 0.064655012,
                0.046207342, 0.069245461, 0.072188022, 0.081182855, 0.100386763,
                0.058091496, 0.08646321, 0.101190576, 0.135233429, 0.116811584,
                0.075231413, 0.101153874, 0.118095289, 0.137355021, 0.128805942,
                0.080398846, 0.094521006, 0.12951405, 0.13439563, 0.156126689,
                0.075334121, 0.118872192, 0.133850714, 0.162576372, 0.172941469,
                0.094847915, 0.120612949, 0.14654267, 0.176608815, 0.197229507,
                0.09277559, 0.137898533, 0.185141754, 0.209088007, 0.232806957,
                0.129129403, 0.172786727, 0.208996453, 0.236350137, 0.271494936,
                0.116629786, 0.182388126, 0.228793711, 0.28245799, 0.283195773,
                0.176345442, 0.231528173, 0.303243233, 0.35616288, 0.381108087,
                0.268501886, 0.322640367, 0.391877968, 0.467791911, 0.503797605,
                0.532425846, 0.548081114, 0.899516676, 0.843405534, 0.902956858
                ),nrow=5,byrow=FALSE))
}

fitAlongChainLength <- function (dByPercentileByLengthData) {
  R=nrow(dByPercentileByLengthData) # 5
  C=ncol(dByPercentileByLengthData) # 14
  ptiles=1:C/C- 1/(2*C)
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
  C=nrow(b)
  ptiles=1:C/C- 1/(2*C)
  d2 <- data.frame(intercept=b[,1],linear=b[,2], x=ptiles)
  fitIntercept <- lm(log(intercept) ~ x, data=d2)
  fitLinear <- lm(log(linear) ~ x, data=d2)
  return(rbind(coefficients(fitIntercept),coefficients(fitLinear)))
}

mapPlacementsToPercentiles <- function(placementData) {
  R=nrow(placementData)
  b=vector(length=R)
  for (i in 1:R) {
    b[i]=findInterval(placementData$DiscrepancyPercent,d[placementData$ChainLength,])
  }
}

getRawPlacementData <- function() {
  df1<-read.csv("C:/Shahar/Projects/Discrepancy/raw_input/data.txt")
  df1$Date <- as.Date(df1$Date,format="%d/%m/%Y")
  return(df1)
}

getSamplePlacementData <- function (df) {
 res <- df %>%
    filter(Date > "2015-07-01" & Date < "2015-07-09") %>%
    group_by(placementId,ChainLength) %>%
    select(Impressions,Served,House) %>%
    summarise(
      sumImps=sum(Impressions),
      sumServed=sum(Served),
      sumHouse=sum(House))   #  filter( Date>"2015-07-08" & Date<"2015-07-15")
 res$DiscrepancyPercent=(res$sumImps-res$sumServed-res$sumHouse)/res$sumImps
 return(res)
}

getDiscrepancyModel <- function(dByPlacementByLength) {
  # get the percentile of each placement-length
  d<-dByPercentileByLength()
  R=nrow(d)
  c=ncol(d)
  newVec <- vector(length=R)
  interval <- newVec
  percentile <- newVec
  interceptForCLModel <- newVec
  slopeForCLModel <- newVec
  t <- fitAlongPercentiles(fitAlongChainLength(d))
  for (i in 1:R) {
    interval[i]=findInterval(dByPlacementByLength$DiscrepancyPercent, b[dByPlacementByLength$ChainLength[i],])
    percentile[i]=interval/C-1/(2*C)
    interceptForCLModel[i]=t[1,1]+t[1,2]*percentile
    slopeForCLModel[i]=t[2,1]+t[2,2]*percentile
  }
  dByPlacementByLength$interval <- interval
  dByPlacementByLength$percentile <- percentile
  dByPlacementByLength$intercept <- interceptForCLModel
  dByPlacementByLength$slope <- slopeForCLModel
  return(dByPlacementByLength)
}

