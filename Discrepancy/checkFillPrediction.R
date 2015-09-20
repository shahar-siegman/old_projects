library(dplyr)
library(ggplot2)
beforeDf <- read.csv("before.tsv",sep="\t")
afterDf <- read.csv("after.tsv",sep="\t")

beforeDf$code.version <- "before"
afterDf$code.version <- "after"

togetherDf <- rbind(beforeDf,afterDf)

togetherDf$Predicted <- as.numeric(togetherDf$Predicted)
togetherDf <- togetherDf %>% select(code.version, Actual , Predicted)
togetherDf$err <- togetherDf$Predicted - togetherDf$Actual

ggplot(data=togetherDf,aes(x=err,color=code.version))+geom_density()



