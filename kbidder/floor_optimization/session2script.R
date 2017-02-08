source('../../libraries.R')
source('./session2functions.R')
net <- 'defy'
size <- '300x250'
if (!exists('reload') || reload) {
  reload = F
  #a <- read.csv('bid_by_network_and_uid_10minutes_WSCS_sample3.csv', stringsAsFactors = F)
  a <- read.csv('bid_by_network_and_uid_15minutes_WSCS_Jan25_Feb6.csv', stringsAsFactors = F)
}
print(1)

FourBidDistribution <- function() {
  ##### single network, diff distribution of 4 bids ######
  d <- singleNetworkLimitedDepth(a,net,size,4)
  d1 <- d %>% arrange(uid, desc(received_ssp_bid)) %>%
    group_by(uid, network) %>%
    mutate(bid_rank=row_number(), bid_diff = received_ssp_bid-lead(received_ssp_bid),
           bid_ratio = logb(received_ssp_bid)-logb(lead(received_ssp_bid)))

  e <- dcast(d1, placement_id + uid ~ bid_counter, value.var = 'received_ssp_bid', fun.aggregate = max)
  e$bid1 <- ifelse(e$bid1==-Inf, NA, e$bid1)
  e$bid2 <- ifelse(e$bid2==-Inf, NA, e$bid2)
  e$bid3 <- ifelse(e$bid3==-Inf, NA, e$bid3)
  e$bid4 <- ifelse(e$bid4==-Inf, NA, e$bid4)

  p_diff <- ggplot(e) + geom_point(aes(x=bid2-bid1, y = bid3-bid2))

  k[[1]] = lm(bid2 ~ bid1+0, e, na.action=na.exclude)
  k[[2]] = lm(bid3 ~ bid2+0, e, na.action=na.exclude)

  e2 <- d %>% mutate(bid_diff_bin = ifelse(bid_ratio<0.1,0,ceiling(bid_ratio/0.25)*0.25)) %>%
    group_by(bid_diff_bin) %>% summarise(cnt=n())
  e2 <- e2 %>% mutate(lead_cnt=lead(cnt), cnt_rat=lead_cnt/cnt)
}


# f <- twoNetworkAnalysis(a, c('pubmatic','defy'), '300x250')
# f <- f %>% filter(pubmatic>0, cb_counter==1)
# p_inter_network <- ggplot(f) + geom_point(aes(x=defy,y=pubmatic))

# frequency of highest and lowest
# d <- a %>% filter(received_ssp_bid >0.25) %>% singleNetworkMultiDepth(net,size,4)
# print(2)
# e <- d %>% group_by(uid, uid_imps) %>% summarise(same_as_highest=sum(same_as_highest),
#                                        same_as_lowest = sum(same_as_lowest),
#                                        all_bids_same = mean(max_uid_bid==min_uid_bid))
# print(3)
# e1 <- e %>% group_by(uid_imps,all_bids_same, same_as_highest) %>% summarise(cnt=n())
# e2 <- e %>% group_by(uid_imps,all_bids_same, same_as_lowest) %>% summarise(cnt=n())
# depth=8
# p1 <- ggplot() + geom_col(data = e1 %>% filter(uid_imps==depth, all_bids_same==0), aes(x=same_as_highest,y=cnt), fill='blue')+
#   geom_col(data = e2 %>% filter(uid_imps==depth), aes(x=same_as_lowest,y=cnt), fill='red', alpha=0.5)+xlim(0,8)

minMaxBidPerUidAnalysis <- function() {
  # max and min bid for uid distribution - detached from bid order
  d <- singleNetworkBidHistogram(a, net, size, 12)

  e <- d %>% mutate(max_bid_bin = ceiling(max_uid_bid/0.25)*0.25,
                    min_bid_bin = ceiling(min_uid_bid/0.25)*0.25)
  e1 <- e %>% group_by(max_bid_bin) %>%  summarise(cnt=n())
  e2 <- e %>% group_by(min_bid_bin) %>%  summarise(cnt=n())

  p1 <- ggplot(e1)+geom_col(aes(x=max_bid_bin, y=cnt))+xlim(0,8.5)
  p2 <- ggplot(e2)+geom_col(aes(x=min_bid_bin, y=cnt))+xlim(0,8.5)
}

# histogram of first bids as a function of how many bids we've seen
b <- a %>% filter(received_ssp_bid > 0, timestamp >='2017-02-06') %>% commonBasicProcessing(net, size)
d1 <- b %>% filter(cb_counter==1) %>%
  mutate(bid_bin=ifelse(received_ssp_bid>0.1, ceiling(received_ssp_bid/0.25)*0.25, 0.1)) %>%
  group_by(uid_imps, bid_bin) %>% summarise(cnt=n()) %>%
  group_by(uid_imps) %>% mutate(bid_frac = cnt/sum(cnt)) %>% ungroup
p1 <- ggplot(d1 %>% filter(uid_imps <=6, bid_bin<=4)) + geom_line(aes(x=bid_bin,y=bid_frac,group=uid_imps,colour=as.factor(uid_imps)))

# scatter plot of 2nd to 1st bid
# fun.aggregate is needed because we have more than 1 placement in the same size format
d2 <- b %>% filter(uid_imps>=2, cb_counter <=2) %>% mutate(cb_counter=paste0('bid',cb_counter)) %>%
  dcast(uid + uid_imps ~ cb_counter, value.var='received_ssp_bid', fun.aggregate=max)

p2 <- ggplot(d2 %>% filter(bid1<=4, bid2<=4)) + geom_point(aes(x=bid1,y=bid2))

# for defy, these groups combined are more than half the data
d3 <- d2 %>% filter(abs(bid1/bid2-1)>0.05,bid1 !=0.6275, bid2 != 0.6275, bid1 <= 4, bid2 <=4 )
k <- lm(bid2 ~ bid1+0, d3)

p3 <- ggplot(d3) + geom_point(aes(x=bid1,y=bid2), colour="#404040") + geom_abline(slope=k$coefficients["bid1"])
print(3)
cat(sprintf("rows: %d", nrow(d2)),
    sprintf("\nabove 4,4: %d", sum(d2$bid1 >= 4 & d2$bid2 >= 4)),
    sprintf("\nbid1 == bid2: %d", sum(d2$bid1 <= 4 & d2$bid2 <= 4 &abs(d2$bid1/d2$bid2-1)<0.05)),
    sprintf("\neither bid equals 0.709: %d" ,
           sum(d2$bid1 <= 4 & d2$bid2 <= 4 & abs(d2$bid1/d2$bid2-1)>0.05 & (d2$bid1 == 0.6275 | d2$bid2==0.6275))),
    sprintf("\nslope: %0.4f, Fit R²: %0.4f", k$coefficients["bid1"], summary(k)$r.squared)
)
