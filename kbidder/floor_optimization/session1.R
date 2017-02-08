source('../../libraries.R')

# a <- read.csv('bid_by_network_and_uid_2minutes_WSCS.csv', stringsAsFactors = F)

#uids with at least two distinct cbs
uids_2plus_cbs <- a %>% group_by(uid) %>% mutate(distinct_cb = n_distinct(cb)) %>%
  ungroup() %>% filter(distinct_cb > 1) %>% `[[`("uid") %>% unique()

b <- a %>% filter(uid %in% uids_2plus_cbs)
b.defy <- b %>% filter(network=='defy', received_ssp_bid>0)
b.pubmatic <- b %>% filter(network=='pubmatic', received_ssp_bid>0)

b.defy.cb_count <- b.defy %>%
  group_by(uid) %>% summarise(distinct_cb=n_distinct(cb))


d <- b %>% group_by(uid) %>% summarise(distinct_cb = n_distinct(cb)) %>%
  group_by(distinct_cb) %>% summarise(n_uid=n()) %>% mutate(total=n_uid*distinct_cb)

b1.defy <-  b.defy %>%
  group_by(uid,cb) %>% summarise() %>% group_by(uid) %>% mutate(num=row_number())

b2.defy <- inner_join(b.defy, b1.defy %>% filter(num<=2), by=c("uid","cb")) %>% mutate(bidnum=ifelse(num==1,'bid1','bid2'))
b3.defy <- b2.defy %>%  group_by(uid,cb,bidnum) %>% summarise(best_defy_bid =max(received_ssp_bid, na.rm=T))

b4.defy <- b3.defy %>% dcast(uid ~ bidnum, value.var = 'best_defy_bid')

p1.defy <- ggplot(b4.defy) + geom_point(aes(x=bid1, y=bid2))

p2.defy <- ggplot() + geom_density(data = b4.defy %>% filter(bid1>=0.25, bid1>bid2),
                                   aes(x=log(bid1)-log(bid2)),colour="blue") +
  geom_density(data = b4.defy %>% filter(bid1>=0.25, bid1<bid2),
               aes(x=log(bid2)-log(bid1)), colour="red")


b1.pubmatic <-  b.pubmatic %>%
  group_by(uid,cb) %>% summarise() %>% group_by(uid) %>% mutate(num=row_number())

b2.pubmatic <- inner_join(b.pubmatic, b1.pubmatic %>% filter(num<=2), by=c("uid","cb")) %>% mutate(bidnum=ifelse(num==1,'bid1','bid2'))
b3.pubmatic <- b2.pubmatic %>%  group_by(uid,cb,bidnum) %>% summarise(best_defy_bid =max(received_ssp_bid, na.rm=T))

b4.pubmatic <- b3.pubmatic %>% dcast(uid ~ bidnum, value.var = 'best_defy_bid')

p1.pubmatic <- ggplot(b4.pubmatic) + geom_point(aes(x=bid1, y=bid2))

p2.pubmatic <- ggplot() + geom_density(data = b4.pubmatic %>% filter(bid1>=0.25, bid1>bid2),
                                   aes(x=log(bid1)-log(bid2)),colour="blue") +
  geom_density(data = b4.pubmatic %>% filter(bid1>=0.25, bid1<bid2),
               aes(x=log(bid2)-log(bid1)), colour="red") +





# stats
writeLines(c(
  paste0('rows: ', nrow(a)),
  paste0('with bids: ',sum(a$received_ssp_bid>0, na.rm=T)),
  paste0('with bids above 25¢: ',sum(a$received_ssp_bid>0.25, na.rm=T)),
  paste0('unique uids: ', length(unique(a$uid))),
  paste0('uids with at least two distinct cbs: ', length(uids_2plus_cbs)),
  paste0('uids with at least ')
  paste0('uids with more than one defy bid from different cbs:',
         b.defy.cb_count  %>%
           filter(distinct_cb > 1) %>% nrow()  )
  ))