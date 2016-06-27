source('../../libraries.R')

# a <- read.csv('hdbd_and_chain_serving.csv', stringsAsFactors = F)

b1 <- a %>% group_by(placement_id,cb) %>%
  summarise(nbids=sum(bid>0,na.rm=T),
            maxbid=max(bid),
            is_served=sum(served_network!="0"),
            is_hdbd_served=sum(hdbd_served))