suppressMessages(library(plyr))

data <- read.csv("../data/cookie_based_session_length_sample1.csv",stringsAsFactors=F)

data$sn <- 1:nrow(data)

ddCheck <- function(pData) {
  print(paste0('length: ', nrow(pData),
    ', length without nas: ', sum(!is.na(pData$placement_id))))
  print(paste0('placement_ids: ', unique(pData$placement_id)))
  print(paste0('first non-Na row:', min(data$sn[!is.na(data$placement_id)])))
}

ddply(data, 'placement_id', ddCheck)