library(dplyr)
groupedAnalysis <- function(rawDF) {
  period1 <- filterAndGroupRawData(rawDF,"2015-07-01","2015-07-08")
  period2 <- filterAndGroupRawData(rawDF,"2015-07-09","2015-07-23")
  period1$DiscrepancyFactor=as.factor(round(period1$DiscrepancyPercent/2,2)*2)
  period2$DiscrepancyFactor=as.factor(round(period2$DiscrepancyPercent/2,2)*2)
  p[[1]]<-ggplot(data=period1,aes(x=DiscrepancyPercent, fill=as.factor(ChainLength))) + geom_density(alpha=0.25)+xlim(-0.5,1)+ylim(0,11)
  p[[2]]<-ggplot(data=period2,aes(x=DiscrepancyPercent, fill=as.factor(ChainLength))) + geom_density(alpha=0.25)+xlim(-0.5,1)+ylim(0,11)
  lapply(p,print)
  return(p)
}

discrepancyCumlativeDistrib <- function(periodDF) {
  p<-periodDF %>%
    group_by(ChainLength) %>%
    mutate(DiscCDF =cume_dist(DiscrepancyPercent),
           DiscRank=min_rank(DiscrepancyPercent))
    write.csv(p,"check_rank.csv")
  return(p)
}

matchDistrib<-function(period1,period2) {
  period1 <- discrepancyCumlativeDistrib(period1)
  period1ByPlacement <- period1 %>%
    group_by(placementId) %>%
    summarise(aveDiscRank=mean(DiscRank))

  period1ByPlacement$aveDiscRank=round(period1ByPlacement$aveDiscRank)

  joined <- period1 %>%
    select(placementId,ChainLength,DiscrepancyPercent,DiscCDF) %>%
    left_join(period2 %>% select (placementId,ChainLength,DiscrepancyPercent), by=c("placementId","ChainLength"))

  joined <- joined %>%
    left_join(period1ByPlacement, by="placementId")

#   joined <- joined %>%
#     left_join(period1 %>% select(ChainLength,DiscRank,DiscrepancyPercent), by=c("ChainLength"="ChainLength","aveDiscRank"="DiscRank"))

}

main <- function(rawDF=data.frame()) {
  if (identical(rawDF,data.frame()))
    rawDF <- getRawPlacementData()
  period1 <- getSamplePlacementData(rawDF)
  period2 <- getTestPlacementData(rawDF)
  joined <- matchDistrib(period1, period2)
}
