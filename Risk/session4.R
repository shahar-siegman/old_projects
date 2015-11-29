source('session3.R')
init <- function() {
  print("Loading..")
  placement.list <- read.csv("top_rev_placements.csv", header=F, col.names="placement_id", stringsAsFactors = F)
  tag.data <- read.csv("tag_performance_top_rev_placements.csv", stringsAsFactors = F)
  current.allocation <- read.csv("allocation_top_rev_placements.csv", stringsAsFactors = F)
  all.placements <- read.csv("all_placements.csv", stringsAsFactors = F)
  # tag.data$chain <- as.character(tag.data$chain)
  # current.allocation$canonic_chain <- as.character(current.allocation$canonic_chain)
  return(list(placement.list=placement.list,
              tag.data=tag.data,
              current.allocation=current.allocation,
              all.placements=all.placements))
}

session4 <- function(x=init()) {
  r <- simulateRiskReallocation(x,"e",0.15, 0.35)
  write.csv(r[[1]],"chain_risk_report.csv")
  write.csv(r[[2]],"placement_risk_report.csv")
}

simulateRiskReallocation <- function(allData, risk.networks, r1Percent, r2Percent) {
  #get next placement
  placement.list <- allData$placement.list
  current.allocation <- allData$current.allocation
  all.placements <- allData$all.placements
  tag.data <- allData$tag.data

  allChainDF <- data.frame(stringsAsFactors = F)
  allPlacementDF <- data.frame(stringsAsFactors = F)

  for (pnum in 1:nrow(placement.list)) {
    print(pnum)
    placementId <- as.character(placement.list[pnum,])
    placement.alloc <- current.allocation %>% filter(tagid==placementId)
    placement.performance <- all.placements %>% filter(tagid==placementId)
    tag.performance <- tag.data %>% filter(placement_id==placementId)
    tag.performance.a <- arrangeTagPerformanceData(tag.performance)
    placement.rev <- sum(tag.performance.a$revenue)
    placement.rcpm <- 1000*placement.rev/sum(tag.performance.a$served)

    placement.floor.price <- max(placement.performance$latest_floor_price)
    rcpmAtNetworkRisk <- calculateNetworkRisk(tag.performance.a, risk.networks)

    tag.floor.prices <- getTagLatestFloorPrice(tag.performance.a)
    rcpmAtEcpmRisk <- calculateEcpmRisk(tag.performance.a, tag.floor.prices, placement.floor.price)

    # the allocation data we have is partial, so this inner_join will drop chains we have performance for but no allocation
    joined <- inner_join(placement.alloc,rcpmAtNetworkRisk) %>% inner_join(rcpmAtEcpmRisk)

    prob <- list(weights = joined$single_weight,
                 isRisk0 = !joined$chain_ecpm_risky & !joined$rcpmAtRisk>0,
                 isRisk1 = joined$chain_ecpm_risky & !joined$rcpmAtRisk>0,
                 ecpmRisk = joined$ecpm_risk,
                 isRisk2 = !joined$chain_ecpm_risky & joined$rcpmAtRisk>0,
                 adxRisk = joined$rcpmAtRisk,
                 isRisk12 = joined$chain_ecpm_risky & joined$rcpmAtRisk>0)
    cf <- do.call(calcProblemCoeffs,prob)
    r1 <- r1Percent * placement.rcpm
    r2 <- r2Percent * placement.rcpm
    if (nrow(placement.alloc) >= 2 &&
        nrow(placement.performance) >= 2 &&
        nrow(tag.performance) >=2) {

      x <- iterativeSmartSolver(r1,r2,cf)
      new.alloc <- colSums(rbind(prob$isRisk0*x["S0"], prob$isRisk1*x["S1"], prob$isRisk2*x["S2"], prob$isRisk12*x["S3"]), na.rm=T)*prob$weights/sum(prob$weights)
    }
    else {
      x <- c(S0=NA, S1=NA, S2=NA, S3=NA)
      new.alloc <- prob$weights/sum(prob$weights)
    }
    chainDF <- joined %>%
      rename(placement_id=tagid, network_risk = rcpmAtRisk, original_weight=single_weight) %>%
      mutate(new_weight=new.alloc*sum(original_weight), change = new_weight-original_weight) %>%
      select(-ordinal_in_tag,-expProp,-sum_weight,-chain_ecpm_risky)

    sow = sum(chainDF$original_weight)

    placementDF <- chainDF %>%
      group_by() %>% summarise(risk1_pre = sum(original_weight*ecpm_risk)/(placement.rcpm*sow),
                               risk2_pre = sum(original_weight*network_risk)/(placement.rcpm*sow),
                               risk1_post = sum(new_weight*ecpm_risk)/(placement.rcpm*sow),
                               risk2_post = sum(new_weight*network_risk)/(placement.rcpm*sow),
                               rcpm = sum(rcpm)) %>%
      mutate(placement_id=as.character(placementId), revenue = placement.rev) %>% c(S0=unname(x["S0"]),S1=unname(x["S1"]),S2=unname(x["S2"]),S3=unname(x["S3"]))
    print(placementId)
    allChainDF <- rbind(allChainDF, chainDF)

    allPlacementDF <- rbind(allPlacementDF, placementDF)
    allPlacementDF$placement_id <- as.character(allPlacementDF$placement_id)
  }
  return(list(allChainDF, allPlacementDF))
}


arrangeTagPerformanceData <- function(tag.performance) {
  # canonical chain
  tag.performance$canonic_chain <- gsub("=\\d+\\.?\\d*","",tag.performance$chain, perl=T)
  tag.performance$network <- substr(tag.performance$tag_name,1,1)
  tag.performance.a <- tag.performance %>% mutate(revenue = income, rcpm = 1000*revenue/served) %>%
    arrange(canonic_chain, ordinal, desc(date_joined))
  # group_by(canonic_chain, tag_name, network, date_joined) %>%  summarise(revenue=sum(income), served=sum(served),
  return(tag.performance.a)
}

calculateNetworkRisk <- function (tag.performance.a, risk.networks) {
  tag.performance.a$is_risky_network <- tag.performance.a$network %in% risk.networks
  tag.performance.b <- tag.performance.a %>% mutate(rcpm=ifelse(is.na(rcpm),0,rcpm)) %>% group_by(canonic_chain) %>%
    summarise(rcpmAtRisk=mean(rcpm*is_risky_network, na.rm=T)) %>% mutate(canonic_chain = as.character(canonic_chain))
  return(tag.performance.b)
}

getTagLatestFloorPrice <- function(tag.performance.a) {
  # this is less straightforward because if there is risk, we take the entire placement's rcpm,
  # and if there isn't, we set it at 0
  tag.performance.a %>% filter(!is.na(floor_price)) %>%
     group_by(canonic_chain, tag_name) %>% summarise(floor_price=head(floor_price,1)) %>%
    ungroup() %>% mutate(canonic_chain = as.character(canonic_chain))
}

calculateEcpmRisk <- function(tag.performance.a, tag.floor.prices, placement.floor.price) {
  chain.risk.a <- tag.floor.prices %>%
    group_by(canonic_chain) %>%
    summarise(chain_ecpm_risky = any(floor_price < placement.floor.price))  %>%
    mutate(canonic_chain = as.character(canonic_chain))
  chain.risk.b <- tag.performance.a %>%
    group_by(canonic_chain) %>%
    summarise(rcpm = mean(rcpm, na.rm=T)) %>%
    mutate(canonic_chain = as.character(canonic_chain)) %>%
    inner_join(chain.risk.a) %>%
    mutate(rcpm=ifelse(is.na(rcpm),0,rcpm), ecpm_risk = chain_ecpm_risky * rcpm)
  return(chain.risk.b)
  }


