source('C:/Shahar/Projects/libraries.R')
library(gridExtra)

loadDF <- function() {
  raw <- read.csv("performance_with_history.csv")
  raw <- raw %>% mutate(impressions = as.numeric(impressions), served=as.numeric(served))
  return(raw)
}

drawChainMain <- function(placementnum, d, r=1) {
  if (missing(d))
    d <- loadDF() %>% aggregateChainData() %>% cleanData()
  placements <- levels(d$placement_id)
  d <- d %>% filter(placement_id==placements[placementnum])
  print(placements[placementnum])
  d$size <- ceiling(log10(d$impressions)*4)
  p.new <- plotChains(d)
  p.legacy <- plotChainsLegacy(d,r)
  p <- grid.arrange(p.legacy, p.new, ncol=2)
  return(p)
}

aggregateChainData <- function(raw) {
d <- raw %>% group_by(placement_id, chain) %>%
  summarise(impressions=sum(ifelse(ordinal==0,impressions,0)), served=sum(served), income=sum(income)) %>%
    mutate(fill = served / impressions,
           ecpm = 1000* income / served,
           rcpm = 1000* income / impressions)

return(d)
}

cleanData <- function(d) {
  d <- d %>% filter(fill <1 & impressions > 5000 & nchar(as.character(chain))>3 & income > 0 & served >50)
}

plotChains <- function(d) {
  d <- calculateXY(d)
  p <- plotGridMain()
  p <- overlayChain(p,d)
  return(p)
}

overlayChain <- function(gggrid,d) {
  p <- gggrid + geom_point(aes(x=x, y=y, size=size, color=chain), data=d)
  m <- ceiling(max(d$ecpm))
  p <- shape(p, m)
  p <- p
  return(p)
}

plotChainsLegacy <- function(d, r) {
  legacy <- ggplot(d) + geom_point(aes(x=fill,y=ecpm,size=size, color=chain)) + theme(legend.position="none")
  m <- ceiling(max(d$ecpm))
  legacy <- shape(legacy, 1, m, r)
}

shape <- function(p,mx, my=mx, r=1) {
  p <- p + coord_fixed(ratio=1/r) + xlim(0,mx) + ylim(0,my) +
    scale_size_continuous(range=c(4,12)) + theme(legend.position="none")
  return(p)
}
