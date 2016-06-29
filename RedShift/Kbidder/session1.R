source('../../libraries.R')

#  a <- read.csv('hdbd_and_chain_serving_t2.csv', stringsAsFactors = F)
#
# b1 <- a %>% group_by(placement_id,cb) %>%
#   summarise(nbids=sum(bid>0,na.rm=T),
#             maxbid=max(bid),
#             median_bid=median(bid),
#             average_bid=mean(bid),
#             is_served=max(served_network!="0"),
#             is_hdbd_served=max(hdbd_served)) %>%
#   mutate(is_chain_served = is_served & !is_hdbd_served)

b2 <- b1 %>% group_by(nbids,is_chain_served,is_hdbd_served) %>% summarise(cnt=n())

b3 <-  b2 %>% group_by(nbids) %>%
  summarise(cases=sum(cnt),
            cases_percent=0,
            fill=sum(ifelse(is_chain_served | is_hdbd_served==1,cnt,0))/sum(cnt),
            percent_by_chain=sum(ifelse(is_chain_served,cnt,0))/sum(ifelse(is_chain_served | is_hdbd_served==1,cnt,0))) %>%
  group_by() %>% mutate(cases_percent=cases/sum(cases)) %>% ungroup()

top_placements <- b1 %>% filter(nbids>=3) %>% group_by(placement_id) %>% summarise(served=sum(is_served)) %>% ungroup() %>%
  arrange(desc(served)) %>% `[[`("placement_id") %>% `[`(seq(1,6))

b4 <-  b1 %>% group_by(placement_id, nbids) %>%
  summarise(cases=n(),
            cases_percent=0,
            fill=sum(ifelse(is_chain_served | is_hdbd_served==1,1,0))/n(),
            percent_by_chain=sum(ifelse(is_chain_served,1,0))/sum(ifelse(is_chain_served | is_hdbd_served==1,1,0))) %>%
  group_by(placement_id) %>% mutate(cases_percent=cases/sum(cases)) %>% ungroup()


p1 <- ggplot(b1)+geom_density(aes(x=maxbid,..scaled.., colour=is_chain_served)) +
  facet_wrap(~nbids) + coord_cartesian(xlim=c(0,5))

p2 <- ggplot(b1%>% filter(nbids>=1))+
  geom_density(aes(x=median_bid,..scaled.., colour=is_chain_served),size=2) +
  facet_wrap(~nbids) + coord_cartesian(xlim=c(0,5))

p3 <- ggplot(b1%>% filter(nbids>=1))+geom_density(aes(x=average_bid,..scaled.., colour=is_chain_served),size=2) +
  facet_wrap(~nbids) + coord_cartesian(xlim=c(0,5))

p4 <- ggplot(b1 %>% filter(nbids>=1, placement_id %in% top_placements))+
  geom_density(aes(x=median_bid,..scaled.., colour=is_chain_served),size=2) +
  facet_grid(placement_id~nbids) + coord_cartesian(xlim=c(0,5))

