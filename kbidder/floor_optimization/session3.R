source('../../libraries.R')


if (!exists('reload') || reload) {
  reload = F
  #a <- read.csv('IndexSSP_first_and_second_bids_10minutes_WSCS.csv', stringsAsFactors = F)
  a <- read.csv('IndexSSP_first_and_second_bids_10minutes_lifehack.csv', stringsAsFactors = F)
}

b <- a %>% mutate(first_bid_bin=ceiling(index_bid/0.25)*0.25,
                  second_bid_bin=ceiling(index_next_bid/0.25)*0.25,
                  second_bid_ratio = ceiling(10*index_next_bid/index_bid)/10)
b1 <- b %>% group_by(first_bid_bin, second_bid_bin) %>% summarise(freq=n())
b2 <- b %>% group_by(first_bid_bin, second_bid_ratio) %>% summarise(freq=n()) %>%
  group_by(first_bid_bin) %>% mutate(frac = freq/sum(freq))



p1 <- ggplot(b1) + geom_tile(aes(x=first_bid_bin,second_bid_bin, fill = log(freq)))+xlim(0,4)+ylim(0,4)
p2 <- ggplot(b2 %>% filter(first_bid_bin<=4)) + geom_tile(aes(x=first_bid_bin,second_bid_ratio, fill = frac))

p3 <- ggplot(b2 %>% filter(first_bid_bin<=4)) +
  geom_line(aes(x=second_bid_ratio, y=frac, colour=as.factor(first_bid_bin), group=as.factor(first_bid_bin))) +
  geom_point(aes(x=second_bid_ratio, y=frac,  shape=as.factor(first_bid_bin)))


d1 <- a %>% select(index_bid,index_next_bid) %>%
  mutate(rf=runif(nrow(a)),
         bid1 = ifelse(rf<0.5,index_bid,index_next_bid),
         bid2 = ifelse(rf>0.5,index_bid,index_next_bid))

p4 <- ggplot(d1 %>% filter(bid1 <= 4, bid2 <= 4)) + geom_point(aes(x=bid1,y=bid2))

d2 <- d1 %>% mutate(bid1_bin = ceiling(bid1/0.8)*0.8,
                    bid2_bin = ceiling(bid2/0.25)*0.25) %>%
  group_by(bid1_bin,bid2_bin) %>% summarise(freq=n()) %>%
  group_by(bid1_bin) %>% mutate(frac=freq/sum(freq))

p5 <- ggplot(d2 %>% filter(bid1_bin <= 4, bid2_bin <= 4)) +
  geom_line(aes(x=bid2_bin,y=log(frac),group=bid1_bin,colour=as.factor(bid1_bin)))
