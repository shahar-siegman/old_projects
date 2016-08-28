source('../../libraries.R')
#b <- read.csv('pulptastic_bids_with_uid.csv', stringsAsFactors=F)

b1 <- b %>% group_by(uid) %>%
  summarise(mintime=min(timestamp),maxtime=max(timestamp),
            distinct_cb=n_distinct(cb),
            distinct_placement=n_distinct(placement_id),
            distinct_url=n_distinct(url_md5))

b2 <- b %>% mutate(max_bid=pmax(aol_bid,cpx_bid,openx_bid,pubmatic_bid,na.rm=T),
                   max_bid_bin=pmin(10,round(max_bid),na.rm=T))
b3 <- b2 %>% filter(kb_win_network!='') %>% group_by(max_bid_bin,kb_win_network) %>%
  summarise(impressions=n(),uids=n_distinct(uid),page_views=n_distinct(cb),
            wins=sum(ifelse(served_tag_source=='',0,1))) %>%
  mutate(winrate=wins/impressions)


p <- ggplot(b3)+
  geom_bar(aes(x=max_bid_bin,y=winrate,colour=kb_win_network,fill=kb_win_network),stat="identity",position="dodge")+
  geom_text(aes(x=max_bid_bin+ifelse(kb_win_network=="l",-0.25,0.25),colour=kb_win_network,y=winrate+0.01,label=sprintf("%d",wins)))+
               scale_y_continuous("winrate",labels=scales::percent)