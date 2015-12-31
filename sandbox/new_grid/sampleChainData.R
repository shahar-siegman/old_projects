source('C:/Shahar/Projects/libraries.R')

loadDF <- function() {
  raw <- read.csv("performance_with_history.csv")
}

drawChainMain <- function(placementnum, d) {
  if (missing(d))
    d <- loadDF() %>% aggregateChainData() %>% cleanData
  p <- plotChains(d, placementnum)
  return(p)
}

aggregateChainData <- function(raw) {
d <- raw %>% group_by(placement_id, chain) %>%
    summarise(impressions=max(impressions),
              served=sum(served),
              income = sum(income)
    ) %>%
    mutate(fill = served / impressions,
           ecpm = 1000* income / served,
           rcpm = 1000* income / impressions)
return(d)
}

cleanData <- function(d) {
  d <- d %>% filter(fill <1 & impressions > 5000 & nchar(chain>3) & income > 0 & served >50)
}

plotChains <- function(d, placementnum) {
  placements <- levels(d$placement_id)
  d <- d %>% filter(placement_id==placements[placementnum]) %>% calculateXY()
  p <- plotGridMain()
  p <- overlayChain(p,d)
  return(p)
}

overlayChain <- function(p,d) {
  d$size <- ceiling(log10(d$impressions)*4)/4
  p <- p + geom_point(aes(x=x, y=y, size=size, color=chain), data=d)
  m <- ceiling(max(d$ecpm))
  p <- p + xlim(0,m) + ylim(0,m)

  p.legacy <- ggplot(d) + geom_point(aes(x=fill,y=ecpm,size=size, color=chain))
  return(list(p, p.legacy))
}
