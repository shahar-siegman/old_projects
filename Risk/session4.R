source('session3.R')
init <- function() {
  placement.list <- read.csv("top_rev_placements.csv", header=F, col.names="placement_id")
  tag.data <- read.csv("tag_performance_top_rev_placements.csv")
  current.allocation <- read.csv("allocation_top_rev_placements.csv")
  all.placements <- read.csv("all_placements.csv")
  return(list(placement.list=placement.list,
              tag.data=tag.data,
              current.allocation=current.allocation,
              all.placements=all.placements))
}

simulateRiskReallocation <- function(allData, risk.networks) {
  #get next placement
  placement.list <- allData$placement.list
  current.allocation <- allData$current.allocation
  all.placements <- allData$all.placements
  tag.data <- allData$tag.data
  for (pnum in 1:nrow(placement.list)) {
      placementId <- as.character(placement.list[pnum,])
      placement.alloc <- current.allocation %>% filter(tagid==placementId)
      placement.performance <- all.placements %>% filter(tagid==placementId)
      tag.performance <- tag.data %>% filter(placement_id==placementId)
      if (nrow(placement.alloc) >= 2 &&
          nrow(placement.performance) >= 2 &&
          nrow(tag.performance) >=2) {
        tag.performance.a <- arrangeTagPerformanceData(tag.performance)
        placement.floor.price <- max(placement.performance$latest_floor_price)
        rcpmAtNetworkRisk <- calculateNetworkRisk(tag.performance.a, risk.networks)

        tag.floor.prices <- getTagLatestFloorPrice(tag.performance.a)
        rcpmAtEcpmRisk <- calculateEcpmRisk(tag.performance.a, tag.floor.prices, placement.floor.price)


#         nMatch <- nrow(semi_join(tag.performance.b, placement.alloc, by="canonic_chain"))
#         nUnMatched1 <- nrow(anti_join(tag.performance.b, placement.alloc, by="canonic_chain"))
#         nUnMatched2 <- nrow(anti_join(placement.alloc, tag.performance.b, by="canonic_chain"))
#         print(paste(nMatch, nUnMatched1, nUnMatched2))
      }
  }
}

arrangeTagPerformanceData <- function(tag.performance) {
  # canonical chain
  tag.performance$canonic_chain <- gsub("=\\d+\\.?\\d*","",tag.performance$chain, perl=T)
  tag.performance$network <- substr(tag.performance$tag_name,1,1)
  tag.performance.a <- tag.performance %>% mutate(revenue = income, rcpm = 1000*revenue/served)
  # group_by(canonic_chain, tag_name, network, date_joined) %>%  summarise(revenue=sum(income), served=sum(served),
  return(tag.performance.a)
}

calculateNetworkRisk <- function (tag.performance.a, risk.networks) {
  tag.performance.a$is_risky_network <- tag.performance.a$network %in% risk.networks
  tag.performance.b <- tag.performance.a %>% filter(!is.na(rcpm)) %>% group_by(canonic_chain) %>%
    summarise(rcpmAtRisk=sum(rcpm*is_risky_network, na.rm=T))
  return(tag.performance.b)
}

getTagLatestFloorPrice <- function(tag.performance.a) {
  # this is less straightforward because if there is risk, we take the entire placement's rcpm,
  # and if there isn't, we set it at 0
  tag.performance.a %>% filter(!is.na(floor_price)) %>%
    arrange(canonic_chain, ordinal, desc(date_joined)) %>% group_by(canonic_chain, tag_name) %>% summarise(floor_price=head(floor_price,1))
}

calculateEcpmRisk <- function(tag.performance.a, tag.floor.prices, placement.floor.price) {
  chain.risk.a <- tag.floor.prices %>%
    group_by(canonic_chain) %>%
    summarise(chain_ecpm_risky = any(floor_price < placement.floor.price))
  chain.risk.b <- tag.performance.a %>%
    group_by(canonic_chain) %>%
    summarise(rcpm = mean(rcpm, na.rm=T)) %>% inner_join(chain.risk.a) %>%
    mutate(ecpm_risk = chain_ecpm_risky* rcpm)
  return(chain.risk.b)
  }

