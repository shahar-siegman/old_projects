getRawPlacementData <- function() {
  rawDF<-read.csv("C:/Shahar/Projects/Discrepancy/raw_input/data.txt")
  rawDF$Date <- as.Date(rawDF$Date,format="%d/%m/%Y")
  return(rawDF)
}

getSamplePlacementData <- function (rawDF) {
  filterAndGroupRawData(rawDF,"2015-07-01","2015-07-08")
}

getTestPlacementData <- function(rawDF) {
  filterAndGroupRawData(rawDF,"2015-07-09","2015-07-23")
}

getPlacementSample <- function() {
  inputDF <- read.csv("C:/Code/Service/Komoona.BigD.NetworkModelUtil/bin/Debug/pcmnts1.txt", header=FALSE)
  inputDF <- inputDF %>% transmute(placementID=V1)
}
