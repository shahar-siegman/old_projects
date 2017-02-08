
addUidCountDistinctCB <- function(df) {
  # total cb count - use n_distinct()
  df <- df %>% group_by(uid) %>% mutate(uid_imps = n_distinct(cb)) %>% ungroup()
  cb.time <- df %>% group_by(uid,cb) %>% summarise(ts=min(timestamp))
  # cb counter - create a new df and create a count there
  uids.cbs <- df %>% group_by(uid,cb) %>% summarise() %>%
    inner_join(cb.time, by=c('uid','cb')) %>% arrange(ts) %>% group_by(uid) %>%
    mutate(cb_counter = row_number())
  if ('cb_counter' %in% names(df))
    df <- df %>% select(-cb_counter) # delete column if exists
  df <- inner_join(df, uids.cbs, by=c("uid","cb"))
  return(df)
}

basicStats <- function(df) {
  # recommended usage is to pre-filter df for a single network
  # if that wasn't done, this function will simply group by network
  # bid rate for network, bid rate above 25¢
  stats <- df %>% group_by(network, uid_imps) %>%
    summarise(rowcount = n(), bid_rate=sum(received_ssp_bid>0, na.rm=T)/n(), bid_rate_25c= sum(received_ssp_bid > 0.25, na.rm=T)/n())

  return(stats)
}

relationOfBids <- function(df,facet_by=NA) {
  # create a scatter plot and a histogram
  # of the 2nd vs. 1st bid and of their ratio
  # the facet_wrap parameter comes from the function input
  df <- df %>% mutate(bid_log_ratio = log(bid2)-log(bid1))
  p1 <- ggplot(df) + geom_point(aes(x=bid1,y=bid2))
  if (!is.na(facet_by))
    p1 <- p1 + facet_wrap(as.formula(facet_by))
  return(p1)
}

singleNetworkLimitedDepth <- function(a, net, size, depth) {
  # a: input data
  # net: name of network to filter by
  # size: ad format
  # depth: number of sequential bids per uid
  e <- commonBasicProcessing(a, net, size) %>% filter(received_ssp_bid >0)
  print(names(e))
  e <- e %>% filter(cb_counter <= depth, uid_imps >= depth) %>%
    mutate(bid_counter = paste0('bid',cb_counter))
  return(e)
}

twoNetworkAnalysis <- function(a, nets, size) {
  b <- commonBasicProcessing(a, net, size)
  b <- b %>% group_by(uid, cb_counter, network) %>%
    summarise(received_ssp_bid = max(received_ssp_bid))
  d <- b %>% mutate(received_ssp_bid = ifelse(is.finite(received_ssp_bid),received_ssp_bid,0)) %>%
    group_by(uid,cb_counter) %>% filter(sum(received_ssp_bid, na.rm=T)>0) %>% ungroup()
  d <- dcast(d, uid + cb_counter ~ network, value.var='received_ssp_bid')
  return(d)
}

singleNetworkMultiDepth <- function(a, net, size, minDepth) {
  b <- a %>% filter(network ==net, ad_size==size) %>%
    group_by(uid) %>% mutate(uid_imps=n())
  b <- b %>% filter(uid_imps >= minDepth)
  d <- b %>% group_by(uid) %>%
    mutate(max_uid_bid = max(received_ssp_bid),
           min_uid_bid= min(received_ssp_bid)) %>% ungroup() %>%
    mutate(same_as_highest=ifelse(received_ssp_bid/max_uid_bid > 0.97, 1,0),
           same_as_lowest=ifelse(min_uid_bid/ received_ssp_bid > 0.97, 1,0))
  return(d)
}

singleNetworkBidHistogram <-  function(a, net, size, minDepth) {
  b <- a %>% filter(network ==net, ad_size==size, received_ssp_bid>0.1) %>%
    group_by(uid) %>% mutate(uid_imps=n())
  b <- b %>% filter(uid_imps >= minDepth)
  d <- b %>% group_by(uid) %>%
    summarise(max_uid_bid = max(received_ssp_bid),
              min_uid_bid= min(received_ssp_bid))
  return(d)
}

commonBasicProcessing <- function(a, net, size) {
  b <- a %>% filter(network %in% net, ad_size %in% size)
  b <- addUidCountDistinctCB(b)
  return(b)
}
