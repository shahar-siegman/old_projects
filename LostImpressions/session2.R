library(zoo)
library(dplyr)

testMain <- function() {
  DF <- main("lost_imps_by_day.csv", "pred_lost.csv", "placement_id", "rel_lost", "pred_lost", "lag_lost", "pred_err",W=14)
}


main <- function(inputFile, outputFile, groupColumn,signalColumn,predColumn,refColumn,errColumn,W) {
  DF <- read.csv(inputFile)
  DF <- DF %>% arrange(placement_id)
  DF <- addPredictionColumns(DF,groupColumn,signalColumn,predColumn,refColumn,errColumn,W)
  write.csv(DF, outputFile)
  return(DF)
}

addPredictionColumns <- function(DF,groupColumn,signalColumn,predColumn,refColumn,errColumn,W) {
  #DF[,predColumn]
  m <- tapply(
    DF[,signalColumn]
    , DF[,groupColumn],
    FUN = function(x)
            if (length(x)>W)
              rollapplyr(x,W+1,prediction,by=1,fill=NA)
            else
              return(x*NA)
  )
  n <- tapply(DF[,signalColumn]
              , DF[,groupColumn],
              FUN = function(x)
                      if (length(x)>W)
                       lag(zoo(x),na.pad=TRUE)
                    else
                      return(x*NA)
  )


  q <- tapply(
    DF[,signalColumn]
    , DF[,groupColumn]
    , FUN=function(x)
            if (length(x)>W)
              rollapplyr(x,W+1,errorEstimate,by=1,fill=NA)
            else
              return(x*NA)
  )
  DF[,predColumn] <- unlist(m)
  DF[,refColumn] <- unlist(n)
  DF[,errColumn] <- unlist(q)
  return (DF)
}

prediction <- function (constLengthVec) {
  # predict the N+1st entry based on N entries. output is a single value
  y <- constLengthVec %>% head(-1) %>% removeExtreme(1,1) %>% mean(na.rm=TRUE)
}

errorEstimate <- function(constLengthVec) {
  y <- constLengthVec %>% head(-1) %>% removeExtreme(1,1) %>% sd(na.rm=TRUE)
}

removeExtreme <- function (vec,nLowest,nHighest) {
 a <- sort(vec, index.return=TRUE)
 e <- length(vec)
 vec[a$ix[1:nLowest]] <- NA
 vec[a$ix[(e-nHighest+1):e]] <- NA
 return (vec)
}

