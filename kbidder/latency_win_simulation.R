source('../libraries.R')

generateWinData <- function(publisherLatencyMean,
                            publisherLatencySD,
                            logisticParameter,
                            zeroLatencyWinRate,
                            sentTimestamp)
{
  # create a vector simulating binary winrate data
  # the winrate has a compound probability:
  # the parameters of the logistic are Gaussian
  # the logistic width parameter is fixed
  # sentTimestamp is a vector of x (the time stamps in which we sent bids)
  # the return value is a corresponding vector of 1's and 0's indicating wins.
  N <- length(sentTimestamp)

  sigmoidBeta0 <- rnorm(N, publisherLatencyMean, publisherLatencySD)
  sigmoidBeta1 <- logisticParameter

  winThreshold <- zeroLatencyWinRate*sigmoid(sentTimestamp, sigmoidBeta0, sigmoidBeta1, reverse=T)
  y <- runif(N)
  isWin <- ifelse(y <= winThreshold,1,0)
  return(isWin)
}

sigmoid <- function(x, beta0, beta1, reverse=F) {
  arg <- (x-beta0)/beta1
  if (reverse)
    1/(1+exp(arg)) else
      1/(1+exp(-arg))
}

rfind <- function(x) seq(along=x)[x != 0]

sentTimestamp <- sort(exp(rnorm(200,3,log(10))))+200
publisherLatencyMean <- 600
publisherLatencySD <- 50
logisticParameter <- 25
zeroLatencyWinRate <- 0.15

y <- generateWinData(publisherLatencyMean,
                     publisherLatencySD,
                     logisticParameter,
                     zeroLatencyWinRate,
                     sentTimestamp)

p <- ggplot(data.frame(sentTimestamp=sentTimestamp,y=y)) +
  geom_point(aes(x=sentTimestamp, y=y))
