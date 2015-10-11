library(dplyr)
library(ggplot2)
perpareForPlot <- function () {
  wd <- "C:/Shahar/Projects/MobileCheckup"
  dataFile <- "ExperimentData.csv"
  mobilePercentFile <- "mobile_percents_oct.csv"
  setwd(wd)
  df=read.csv(dataFile)

  #extract floor price
  nr=nrow(df)
  fp=numeric(nr)
  chain=as.character(df$GlobalChain)
  for (i in 1:nr) {
    s=strsplit(chain[i], split = ":")[[1]]
    s=s[df$Order[i]+1]
    s=strsplit(s,split="=")[[1]]
    fp[i]=as.numeric(s[2])
  }
  df$floorPrice=fp


  # join with mobile percents
  m <- read.csv(mobilePercentFile)
  dfj <- inner_join(df,m)

  # calculate comparison metrics mobile vs. desktop
  dfj1 <- dfj %>%
    transmute(PlacementId
              , Date
              , Network
              , Order
              , floorPrice
              , GlobalChain
              , GlobalType
              , MobileImpressions = GlobalImpressions * mobilePercent
              , MobileServed = MobileImpressions * ExperimentFill
              , MobileIncome = MobileServed * ExperimentEcpm/1000
              , DesktopImpressions = GlobalImpressions - MobileImpressions
              , DesktopServed = GlobalServed - MobileServed # ifelse(GlobalServed >= MobileServed & GlobalServed >=10, GlobalServed - MobileServed, NA)
              , DesktopIncome = GlobalIncome - MobileIncome
              , MobileFill = MobileServed / MobileImpressions
              , MobileEcpm = ExperimentEcpm
              , MobileRcpm = MobileEcpm * MobileFill
              , DesktopFill = DesktopServed / DesktopImpressions
              , DesktopEcpm = ifelse(DesktopServed > 0, DesktopIncome / DesktopServed, NA)
              , DesktopRcpm = DesktopEcpm * DesktopFill                  )
}

sumByDate <- function(dfj) {
  dfj2 <- dfj %>% group_by(PlacementId,GlobalChain,GlobalType,Order,Network, floorPrice, ExperimentChain,
                           ExperimentType, mobilePercent ) %>%
    summarise(
      globalImpressions = sum(GlobalImpressions)
      , globalServed= sum(GlobalServed)
      , globalIncome = sum(GlobalIncome)
      , globalFill = globalServed/globalImpressions
      , globalEcpm = 1000*globalIncome/globalServed
      , globalRcpm = globalEcpm*globalFill
      , experimentImpressions = sum(ExperimentImpressions)
      , experimentServed = sum(ExperimentServed)
      , experimentIncome = sum(ExperimentIncome)
      , experimentFill = experimentServed/experimentImpressions
      , experimentEcpm = 1000*experimentIncome/experimentServed
      , experimentRcpm = experimentEcpm * experimentFill
    )
}

plotData <- function(dfj1) {
  ggplot(dfj1)+geom_boxplot(aes(x=floorPrice,y=MobileFill/DesktopFill)) + facet_grid(Network ~ PlacementId) + coord_cartesian(ylim = c(0, 2))

  ggplot(dfj1)+geom_boxplot(aes(x=1, y=MobileFill), color="blue", fill="blue",alpha=0.3) + geom_boxplot(aes(x=1, y=DesktopFill),color="red",fill="red",alpha=0.3) + facet_grid(Network ~ PlacementId)
}

analyzeFillByNetworkAndFormt <- function (dfj) {
  dfj2 <- sumByDate(dfj)
  formats <- read.csv("formats.txt",sep="\t")
  dfj3 <- left_join(formats,dfj2)
  r6 <- dfj3 %>% ungroup() %>% filter(globalServed>100 & experimentServed > 100) %>% transmute(Network, Format,globalFill, experimentFill, fillRatio=experimentFill/globalFill)
  list(ggplot(r6)+geom_density(aes(x=log(fillRatio), color=Format, fill=Format),alpha=0.5),
  ggplot(r6)+geom_density(aes(x=log(fillRatio), color=Network, fill=Network),alpha=0.5))
}
