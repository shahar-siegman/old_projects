source("../libraries.R")

# assume "a" from session1.R is available.
# print(1)
# a4 <- a3 %>%
#   mutate(date=as.Date(date),
#          year_mon=as.yearmon(date),
#          ecpm=ifelse(served==0,NA,1000*revenue/served),
#          profit_ecpm=ifelse(served==0,NA,1000*profit/served),
#          margin=1-floor_price/ecpm) %>%
#   group_by(tagid) %>%
#   filter(!all(is.na(floor_price)),
#          min(date)<='2016-01-30',
#          date>='2016-01-01') %>%
#   mutate(ref_floor_price=first(floor_price)) %>%
#   ungroup()

print(2)
a5 <- a4 %>%
  mutate(floor_price_bin=round(ref_floor_price*2.5)/2.5,
         norm_floor=ifelse(floor_price_bin==0,floor_price+0.9,floor_price/ref_floor_price))
  # filter(!all(norm_floor==1)) %>%
print(3)
a6 <- a5 %>%
  group_by(floor_price_bin,date) %>%
  summarise(median_margin=median(margin),
            median_norm_floor=mean(norm_floor),
            cnt=n(),
            served=sum(served),
            profit=sum(profit),
            revenue=sum(revenue)) %>%
  group_by(date) %>%
  mutate(served_frac=served/sum(served)) %>% ungroup() %>%
  mutate(revshare=profit/revenue)


p1 <- ggplot(a6 %>% filter(floor_price_bin <=2)) +
  geom_line(aes(x=as.Date(date),y=median_norm_floor,colour=as.factor(floor_price_bin), group=floor_price_bin),size=2) +
  coord_cartesian(ylim=c(0.5,1.2))+
  scale_x_date()

p2 <- ggplot(a6 %>% filter(floor_price_bin <=2)) +
  geom_line(aes(x=as.Date(date),y=served_frac,colour=as.factor(floor_price_bin), group=floor_price_bin),size=2) +
  coord_cartesian(ylim=c(0,1))+
  scale_x_date()

p3 <- ggplot(a6 %>% filter(floor_price_bin <=2)) +
  geom_line(aes(x=date,y=median_margin,colour=as.factor(floor_price_bin), group=floor_price_bin),size=2) +
  coord_cartesian(ylim=c(0,1))+
  scale_x_date()

p4 <- ggplot(a6 %>% filter(floor_price_bin <=2)) +
  geom_line(aes(x=date,y=revshare,colour=as.factor(floor_price_bin), group=floor_price_bin),size=2) +a6 <- a5 %>%
  group_by(floor_price_bin,date) %>%
  summarise(median_margin=median(margin),
            median_norm_floor=mean(norm_floor),
            cnt=n(),
            served=sum(served),
            profit=sum(profit),
            revenue=sum(revenue)) %>%
  group_by(date) %>%
  mutate(served_frac=served/sum(served)) %>% ungroup() %>%
  mutate(revshare=profit/revenue)+
  scale_x_date()
