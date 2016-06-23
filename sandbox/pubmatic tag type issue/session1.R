source('../../libraries.R')

a <- read.csv('performance_with_good_bad_jun23.csv',stringsAsFactors = F)

b <- a %>% filter(tag_type %in% c('good','bad'),!is.na(ordinal),
                  impressions>100,
                  as.Date(date_joined)>='2016-06-01') %>%
  mutate(floor_price_bin=round(floor_price*2.5)/2.5,
         ordinal=as.factor(ordinal),
         tag_type=as.factor(tag_type)) %>%
  group_by(placement_id, tag_type, ordinal, floor_price_bin) %>%
  summarise(impressions=sum(impressions), served=sum(served), income=sum(income)) %>%
  mutate(fill=served/impressions, ecpm=1000*income/served, rcpm=1000*income/impressions)

d <- b %>% dcast(placement_id + ordinal + floor_price_bin ~ tag_type,value.var="fill") %>%
  filter(!is.na(bad),!is.na(good)) %>%
  mutate(win=ifelse(good>bad,1,0))

g <- b %>% group_by(floor_price_bin, tag_type)  %>% summarise(cnt=n(),served=sum(served),imps=sum(impressions), income=sum(income)) %>%
  mutate(ecpm=1000*income/served, fill=served/imps, rcpm=1000*income/imps)
p1 <- ggplot(b) + geom_point(aes(x=placement_id,y=fill,colour=tag_type)) + facet_grid(floor_price_bin~ordinal) #+coord_cartesian(ylim=c(0,0.2))
p2 <- ggplot(b) + geom_point(aes(x=placement_id,y=ecpm,colour=tag_type)) + facet_grid(floor_price_bin~ordinal)
print(c(sum(d$win), sum(d$win)/nrow(d), mean(d$good), mean(d$bad)))

p3 <- ggplot(b) + geom_density(aes(x=rcpm,colour=tag_type))+ facet_wrap(~floor_price_bin)