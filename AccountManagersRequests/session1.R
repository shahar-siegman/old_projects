library(xlsx)
library(dplyr)
readInput <- function() {
  rawDF <- read.xlsx("data2.xlsx",1)
}

plotMarginAnalysis <- function(rawDF) {
  # plot general margin in a time period
  startDate <- "2015-10-01"
  marginBydate <- rawDF %>% filter()
}
