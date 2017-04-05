source('../../libraries.R')

a <- read.csv('cookie_based_result1.csv',stringsAsFactors = F)

check_prediction_pubmatic <- function() {
  b1 <- a %>%
    select(placement_id, uid, pubmatic_bid,pubmatic_cum_bids, pubmatic_bidAboveThres,pubmatic_prediction) %>%
    filter(pubmatic_cum_bids>5, pubmatic_cum_bids < 35, pubmatic_bid==1)


  p_pubmatic1 <- ggplot(b1)+
    geom_line(aes(x=pubmatic_cum_bids,y=pubmatic_prediction,group=uid, colour=uid))+
    facet_wrap(~placement_id)+guides(colour=FALSE)

  b2 <- b1 %>% mutate(prediction_bin = round(pubmatic_prediction,1)) %>%
    filter(pubmatic_cum_bids >= 10, pubmatic_cum_bids <= 15)

  b3 <- b2 %>%
    group_by(placement_id,prediction_bin) %>%
    summarise(total_bids = n(), total_above = sum(pubmatic_bidAboveThres)) %>%
    mutate(actual = total_above/total_bids)

  p_pubmatic2 <- ggplot(b3,aes(x=prediction_bin,y=actual,shape=placement_id)) + geom_point(aes(size=0.75))+
    geom_smooth(method="lm")

  return(p_pubmatic2)
}

check_prediction_defy <- function() {
  b1 <- a %>%
    select(placement_id, uid, defy_bid,defy_cum_bids, defy_bidAboveThres,defy_prediction) %>%
    filter(defy_cum_bids>5, defy_cum_bids < 35, defy_bid==1)


  p_defy1 <- ggplot(b1)+
    geom_line(aes(x=defy_cum_bids,y=defy_prediction,group=uid, colour=uid))+
    facet_wrap(~placement_id)+guides(colour=FALSE)

  b2 <- b1 %>% mutate(prediction_bin = round(defy_prediction,1)) %>%
    filter(defy_cum_bids >= 10, defy_cum_bids <= 15)

  b3 <- b2 %>%
    group_by(placement_id,prediction_bin) %>%
    summarise(total_bids = n(), total_above = sum(defy_bidAboveThres)) %>%
    mutate(actual = total_above/total_bids)

  p_defy2 <- ggplot(b3,aes(x=prediction_bin,y=actual,shape=placement_id)) + geom_point(aes(size=0.75))+
    geom_smooth(method="lm")

  return(p_defy2)
}

p_pubmatic2 <- check_prediction_pubmatic()
p_defy2 <- check_prediction_defy()