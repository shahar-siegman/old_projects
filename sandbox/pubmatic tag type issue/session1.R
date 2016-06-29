source('../../libraries.R')

a <- read.csv('performance_with_good_bad_jun27.csv',stringsAsFactors = F)

b1 <- a %>% filter(tag_type %in% c('good','bad'),!is.na(ordinal),
                  impressions>100,
                  as.Date(date_joined)>='2016-06-20',
                  as.Date(date_joined)<='2016-06-29') %>%
  mutate(floor_price_bin=round(floor_price*2.5)/2.5,
         ordinal=as.factor(ordinal),
         tag_type=as.factor(tag_type),
         date_joined=as.Date(date_joined))
# randomize the sample
b1$tag_type <- ifelse(runif(nrow(b1))>0.30,'good','bad')
b2 <- b1 %>%
  group_by(placement_id, tag_type, ordinal, floor_price_bin) %>%
  summarise(impressions=sum(impressions), served=sum(served), income=sum(income)) %>%
  mutate(fill=served/impressions, ecpm=1000*income/served, rcpm=1000*income/impressions)

d <- b2 %>% dcast(placement_id + ordinal + floor_price_bin ~ tag_type,value.var="fill") %>%
  filter(!is.na(bad),!is.na(good)) %>%
  mutate(win=ifelse(good>bad,1,0))

g <- b2 %>% group_by(floor_price_bin, tag_type)  %>% summarise(cnt=n(),served=sum(served),imps=sum(impressions), income=sum(income)) %>%
  mutate(ecpm=1000*income/served, fill=served/imps, rcpm=1000*income/imps)
p1 <- ggplot(b2) + geom_point(aes(x=placement_id,y=fill,colour=tag_type)) + facet_grid(floor_price_bin~ordinal) #+coord_cartesian(ylim=c(0,0.2))
p2 <- ggplot(b2) + geom_point(aes(x=placement_id,y=ecpm,colour=tag_type)) + facet_grid(floor_price_bin~ordinal)
print(c(sum(d$win), sum(d$win)/nrow(d), mean(d$good), mean(d$bad)))

p3 <- ggplot(b2) + geom_density(aes(x=rcpm,colour=tag_type))+ facet_wrap(~floor_price_bin)

b3 <- b1 %>% filter(tag_type=='bad') %>% group_by(date_joined,ordinal,floor_price_bin) %>%
  summarise(impressions=sum(impressions), served=sum(served), income=sum(income)) %>%
  mutate(fill=served/impressions, ecpm=1000*income/served, rcpm=1000*income/impressions)

p4 <- ggplot(b3, aes(x=date_joined,y=fill,group=floor_price_bin,colour=as.factor(floor_price_bin)))+
  geom_line()+
  geom_point()+
  scale_x_date()+
  facet_wrap(~ ordinal)
