source('../../libraries.R')
cutoff <- 60 # number of seconds permitted to keep bid

shortTimeAddedValue <- function(bid_col, lag_bid_col, timediff_col)
  ifelse(timediff_col < cutoff & lag_bid_col > bid_col, lag_bid_col-bid_col,0)
filenames <- c('fark_bidding_data_20min_nov20',
            'fark_bidding_data_20min_nov18',
            'cheatsheet_1.8Mrows_nov21')
filenum <- 3
a = read.csv(paste0(filenames[filenum],'.csv'),stringsAsFactors = F)
a$timestamp <- as.POSIXct(a$timestamp,format="%F %H:%M:%S")
if (!"estimated_timeout" %in% names(a))
  a$estimated_timeout=1000

a1 <- a  %>% arrange(placement_id, uid,timestamp) %>%
  mutate(received_ssp_bid=ifelse(is.na(received_ssp_bid),0,received_ssp_bid),
         received_bid_by_timeout = ifelse(!is.na(rests) & rests>estimated_timeout,0,received_ssp_bid))




a1a <- a1 %>%
  select(placement_id, uid, timestamp, cb, network,received_ssp_bid) %>%
  dcast(placement_id + cb + uid + timestamp ~ network, value.var="received_ssp_bid",
        fun.aggregate = mean)

a1b <- a1 %>%
  select(placement_id, uid, timestamp, cb, network, received_bid_by_timeout) %>%
  mutate(network=paste0(network,"_by_timeout")) %>%
  dcast(placement_id + cb + uid + timestamp ~ network, value.var="received_bid_by_timeout",
        fun.aggregate = mean)

a1c <- a1 %>%
  select(placement_id, uid, timestamp, cb, served_tag) %>%
  #mutate(served_tag_network=substr(served_tag,1,1)) %>%
  mutate(winner_served=ifelse(substr(served_tag,1,1) %in% c('S','o','l'),T,F)) %>%
  select(-served_tag) %>%
  distinct()

a2 <- a1a %>% inner_join(a1b, by=c("placement_id","uid","timestamp","cb")) %>%
  inner_join(a1c, by=c("placement_id","uid","timestamp","cb")) %>%
  group_by(placement_id, uid) %>%
  mutate(time_diff=difftime(timestamp, lag(timestamp),units="secs")) %>%
  ungroup() %>%
  mutate(time_diff=ifelse(is.na(time_diff),-59,time_diff),
         win=pmax(aol,cpx,index,pubmatic,sovrn,na.rm=T),
         win_by_timeout=pmax(aol_by_timeout,cpx_by_timeout,sovrn_by_timeout,na.rm=T))

a3 <- a2 %>% filter(uid!="") %>% group_by(placement_id, uid) %>%
  mutate(
#    aol_added_value = shortTimeAddedValue(aol,lag(aol),time_diff),
    cpx_added_value = shortTimeAddedValue(cpx,lag(cpx),time_diff),
    index_added_value = shortTimeAddedValue(index,lag(index),time_diff),
    pubmatic_added_value = shortTimeAddedValue(pubmatic,lag(pubmatic),time_diff),
    sovrn_added_value = shortTimeAddedValue(sovrn,lag(sovrn),time_diff),
    win_added_value = shortTimeAddedValue(win_by_timeout,lag(win),time_diff),
    win_by_timeout_added_value = shortTimeAddedValue(win_by_timeout,lag(win_by_timeout),time_diff),
    winner_was_served = lag(winner_served))

nts = c(
#  'aol',
  'cpx',
  'index',
  'pubmatic',
  'sovrn'
  )
measure_vars=paste0(nts,'_added_value')


a4 <- a3 %>% melt(id.vars=c("placement_id", "cb","uid","timestamp"),
                  measure.vars=measure_vars,
                  variable.name="network",
                  value.name="added.value") %>%
  arrange(placement_id, uid, timestamp,network) %>%
  mutate(network=ifelse(network=="sovrn_added_value","sovrn",substr(network,1,3)))

p1 <- ggplot(a2) + geom_histogram(aes(x=time_diff),stat="bin",binwidth=30)

a5 <- a4 %>% filter(added.value > 0.1) %>% mutate(added.value=pmin(added.value,1.2))
p2 <- ggplot(a5 %>% filter(network=="win")) + geom_histogram(aes(x=added.value),stat="bin",binwidth=0.05)


bid.cache.summary <- list()
bid.cache.summary$impressions.in.sample <- nrow(a2)
bid.cache.summary$impressions.with.uid <- nrow(a3)
bid.cache.summary$impressions.with.perceding.within.time <- sum(a3$time_diff >= 0 & a3$time_diff <=60, na.rm=T)
bid.cache.summary$impressions.with.win.added.value <- sum(a3$win_added_value > 0, na.rm=T)
bid.cache.summary$impressions.where.added.value.is.from.late.bids <-
  sum(a3$win_added_value>0, na.rm=T) - sum(a3$win_by_timeout_added_value>0, na.rm=T)
bid.cache.summary$added.value.from.late.bids <-
  sum(a3$win_added_value, na.rm=T) - sum(a3$win_by_timeout_added_value, na.rm=T)

bid.cache.summary$impressions.reusing.winner <- sum(a3$winner_was_served & a3$win_added_value > 0, na.rm=T)
bid.cache.summary$impressions.reusing.winner.value <- sum(ifelse(a3$winner_was_served & !is.na(a3$win_added_value), a3$win_added_value, 0))
bid.cache.summary$sent.bids.value <- sum(a2$win)
bid.cache.summary$added.bid.value <- a4 %>% filter(network=="win") %>% `[[`("added.value") %>% sum(na.rm=T) - bid.cache.summary$impressions.reusing.winner.value





