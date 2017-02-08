source('../../libraries.R')
#a = read.csv('allStats.csv',stringsAsFactors = F)
# a <- a %>% mutate(bidImprove = reuse_bid_bid - first_bid_cpm)
b <- a %>% filter(length(reuse_bid_code)> 0) %>%
  mutate(reuse_bid_code = ifelse(bidImprove <=0, NA, reuse_bid_code),
         reuse_bid_bid = ifelse(bidImprove <=0, NA, reuse_bid_bid),
         bidImprove = ifelse(bidImprove <=0, NA, bidImprove))

c <- a %>% group_by(first_bid_code) %>% summarise(full_count=n())

c1 <- b %>% filter(!is.na(reuse_bid_code),bidImprove>0.2) %>% group_by(first_bid_code) %>%
  summarise(cnt = n()) %>% ungroup() %>%
  arrange(desc(cnt)) %>% left_join(c, by='first_bid_code') %>% select(first_bid_code, full_count, cnt) %>%
  mutate(percent = cnt/full_count)
print(c1)
# %>% group_by() %>% mutate(percent = cnt/sum(cnt))
p1 <- ggplot(b) + geom_histogram(aes(x=bidImprove,y=..density..),binwidth=0.25) +
  facet_grid(first_bid_code ~ .)+
  coord_cartesian(xlim=c(-0.25,2.5))


p2 <- ggplot(b %>% filter(reuse_bid_bid>=2)) + geom_histogram(aes(x=bidImprove,y=..density..),binwidth=0.25) +
  facet_grid(first_bid_code ~ .)+
  coord_cartesian(xlim=c(-0.25,2.5))
