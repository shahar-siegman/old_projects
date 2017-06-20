library(ggplot2)
library(dplyr)
a <- read.csv('../data/win_probability_sample3.csv', stringsAsFactors = F)

a$win = as.logical(a$win)
a$served_a_tag = as.logical(a$served_a_tag)

a1 <- a %>% filter(!is.na(sent_bid), sent_bid>0, pc_wb>0) %>%
  mutate(sent_bid_bin = pmin(floor(sent_bid/0.1)*0.5,8.0),
         bid_ts_bin = as.factor(pmin(floor(bid_ts/500)*500,2500)))

b1 <- a1 %>% group_by(pc_res,pc_wb,sent_bid_bin,bid_ts_bin) %>%
  summarise(bin_imps = n(), wins = sum(win), served = sum(served_a_tag)) %>%
  ungroup() %>%
  mutate(win_rate = wins/bin_imps,
         served_rate = served/wins) %>%
  arrange(pc_res,pc_wb,sent_bid_bin,bid_ts_bin) %>%
  filter(sent_bid_bin < 8.0)

p <- ggplot(b1) +
  geom_line(aes(x=sent_bid_bin,y=win_rate,group=bid_ts_bin,colour=bid_ts_bin)) +
  facet_wrap(pc_wb ~ pc_res)
