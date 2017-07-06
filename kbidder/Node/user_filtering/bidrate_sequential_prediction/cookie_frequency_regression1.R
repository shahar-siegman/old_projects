suppressMessages(library(plyr))

ouputFileExtensionString = '_playProbs.csv'
print('Hello R!')
if (exists('externalArgs')) {
  args <- externalArgs
} else {
  # or, get variables from the command line
  args <- commandArgs(trailingOnly = TRUE)
}

# args[1]: name of csv file to load
argument1 <- args[1]

# parse argument1 to synthesize an output file name
inputDir <- dirname(argument1)
inputFile <- basename(argument1)
inputFileNoExt <- strsplit(inputFile,'.',fixed=T)[[1]][1]
outputFile <- ifelse(length(argument2)>3,
  argument2,
  file.path(inputDir,paste0(inputFileNoExt,ouputFileExtensionString)))

# load the csv into a dataframe
data <- read.csv(argument1,stringsAsFactors=F)

regressionWrap <- function(regressData) {
  # normalize so that n_cookies(1)=1
  initialImps <- regressData$n_cookies[regressData$impressions_per_cookie_50==1]
  regressData$n_cookies = regressData$n_cookies/initialImps

  #prepare and run the regression
  regressData$l_cookies = log(regressData$n_cookies)
  regressData$l_imps = sqrt(regressData$impressions_per_cookie_50)
  excludedRows <-
    regressData[regressData$impressions_per_cookie_50==50 | regressData$impressions_per_cookie_50 <=2,]
  subs <- regressData$impressions_per_cookie_50<50 &
      regressData$impressions_per_cookie_50>2
  res <- lm(l_cookies ~ l_imps, regressData, subs)

  # prepare the output data frame
  pred <- data.frame(placement_id = regressData$placement_id[1], impression = 1:50, n_cookies_actual=0)

  # copy actual to the output (not used in production)
  for (i in 1:nrow(regressData)) {
    imps_per_cookie <- regressData$impressions_per_cookie_50[i]
    actual <- regressData$n_cookies[regressData$impressions_per_cookie_50==imps_per_cookie]
    pred$n_cookies_actual[imps_per_cookie] <- actual
  }

  # calculate the horizon impression count
  t <- 0
  for (i in 50:150) {
    t <- t + exp(sqrt(i)*res$coefficients[2] + res$coefficients[1])
  }

  # calculate the impression ratio: the "play_prob"
  pred$n_cookies_predict <- exp(res$coefficients[1] + res$coefficients[2]*sqrt(pred$impression))
  pred$n_cookies_predict[50]=t
  pred$cum_relative_imps = cumsum(pred$n_cookies_predict)/sum(pred$n_cookies_predict)
  pred$play_prob = pred$n_cookies_predict/exp(res$coefficients[1] + res$coefficients[2]*sqrt(pred$impression-1))
  return(pred)
}

output <- ddply(data, 'placement_id', regressionWrap)

print(paste0('writing ',outputFile))
write.csv(output, outputFile, row.names=F)