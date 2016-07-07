source('../../libraries.R')

a <- read.csv('hdbd_performance_with_geo_device_plid_59cbc.csv', stringsAsFactors = F)

a1 <- a %>% arrange(cb,timestamp_) %>% group_by(cb) %>%
  summarise(geo_country=first(geo_country),
            ua_device_type=first(ua_device_type),
            served_network=first(served_network),
            hdbd_served=max(hdbd_served),
            max_bid=max(bid),
            served_bid=sum(ifelse(network_letter==served_network,bid,0))) %>%
  mutate(geo_us=ifelse(geo_country=='US','US','non-US'),
         served=ifelse(served_network=='0',0,1))

a2 <- a1 %>% group_by(geo_us,ua_device_type,served,hdbd_served) %>% summarise(cases=n())
b <- a %>% filter(network_letter!="") %>% dcast(cb ~ network_letter, value.var="bid")