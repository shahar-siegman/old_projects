source("../libraries.R")

# commented out for speed
# k6 <- a %>% mutate(ecpm_bin=round(2.5*total_ecpm)/2.5,
#                    date=as.Date(date))%>%
#   filter(!is.na(ecpm_bin)) %>%
#   group_by(tagid,as.yearmon(date)) %>%
#   filter(sum(impressions)>5000) %>%
#   group_by(ecpm_bin,date) %>%
#   summarise(impressions=sum(as.numeric(impressions)),
#             served=sum(as.numeric(served)),
#             revenue=sum(revenue),
#             median_fill=median(fill)/100) %>%
#   mutate(fill=served/impressions)

prepareYoyCompare <- function(q)
{
  q <- q %>%mutate(fill=served/impressions,
                   year=as.numeric(format(date,"%Y")),
                   month=as.numeric(format(date,"%m")),
                   mday=as.numeric(format(date,"%d"))) %>%
    filter(date >='2014-11-29') %>%
    mutate(year_group=year+ifelse(month>=11,1,0),
           scale_date=date-365*(year_group-2014)) %>%
    filter(month %in% c(1,2,3,12))
  return(q)
}
k7 <- k6 %>% prepareYoyCompare()

# 2015 vs. 2016 overlay
pk5 <- ggplot(k7 %>% filter(ecpm_bin<1.61)) +
  geom_line(aes(x=scale_date, y=median_fill,group=year_group, colour=year_group),size=1.25)+
  geom_point(aes(x=scale_date, y=ifelse(day.of.week(month,mday,year)==0,median_fill,NA), colour=year_group),size=2)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  scale_x_date(date_labels="%m/%d")+
  xlab("Date")+
  ylab("Median Fill") +
  facet_wrap(~ecpm_bin)


pk6 <- ggplot(k7 %>% filter(ecpm_bin<1.61)) +
  geom_line(aes(x=scale_date, y=1000*revenue/served,group=year_group, colour=year_group),size=1.25)+
  geom_point(aes(x=scale_date, y=ifelse(day.of.week(month,mday,year)==0,1000*revenue/served,NA), colour=year_group),size=2)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::dollar)+
  scale_x_date(date_labels="%m/%d")+
  xlab("Date")+
  ylab("eCPM") +
  facet_wrap(~ecpm_bin,scales="free")


#q <- readQ()
print(1)
q7 <- q %>%
  mutate(ecpm_bin=round(2500*revenue/served)/2.5,
         n_available=ifelse(str_length(available_down)==0,0,str_count(available_down,";")+1),
         date=as.Date(date-as.POSIXlt(date)$wday)) %>%
  group_by(year_mon,clean_url) %>%
  filter(sum(impressions)>5000, !is.na(ecpm_bin)) %>%
  ungroup()

print(2)

q8 <- q7 %>%
  group_by(date,ecpm_bin,n_available, available_down) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(served/impressions)) %>%
  ungroup()

print(3)


print(4)

q9 <- q8 %>%
  filter(n_available >=3) %>%
  prepareYoyCompare() %>%
  group_by(available_down,year_group, ecpm_bin) %>%
  filter(n() >= 3, !available_down %in% c("aol","aol;pulsepoint","pulsepoint")) %>%
  group_by(available_down, ecpm_bin) %>%
  filter(n_distinct(year_group) == 2) %>%
  ungroup()


q9.5 <- q8 %>%
  mutate(has_aol=str_count(available_down,"aol"),
         has_openx=str_count(available_down,"openx"),
         has_pubmatic=str_count(available_down,"pubmatic"),
         has_pulsepoint=str_count(available_down,"pulsepoint"))

q9.6 <- rbind(
  q9.5 %>% group_by(date, ecpm_bin, n_available, has_aol) %>% summarise(median_fill=median(served/impressions), served=sum(as.numeric(served)), impressions=sum(as.numeric(impressions)) ) %>% rename(has=has_aol) %>% mutate(network="aol"),
  q9.5 %>% group_by(date, ecpm_bin, n_available, has_openx) %>% summarise(median_fill=median(served/impressions), served=sum(as.numeric(served)), impressions=sum(as.numeric(impressions))) %>% rename(has=has_openx) %>% mutate(network="openx"),
  q9.5 %>% group_by(date, ecpm_bin, n_available, has_pubmatic) %>% summarise(median_fill=median(served/impressions), served=sum(as.numeric(served)), impressions=sum(as.numeric(impressions))) %>% rename(has=has_pubmatic) %>% mutate(network="pubmatic"),
  q9.5 %>% group_by(date, ecpm_bin, n_available, has_pulsepoint) %>% summarise(median_fill=median(served/impressions), served=sum(as.numeric(served)), impressions=sum(as.numeric(impressions))) %>% rename(has=has_pulsepoint) %>% mutate(network="pulsepoint")
  ) %>%
  prepareYoyCompare()




print(5)
q10 <- q7 %>%
  group_by(date,ecpm_bin,n_available) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(served/impressions)) %>%
  ungroup() %>% prepareYoyCompare()

print(6)

pq7 <- ggplot(q9 %>% filter(ecpm_bin<1.21)) +
  geom_line(aes(x=scale_date,y=median_fill, group=as.factor(year_group), colour=as.factor(year_group)), size=1.25) +
  facet_grid(ecpm_bin~available_down)+
  xlab("Date")+
  ylab("Median Fill") +
  theme(axis.text=element_text(size=14,face="bold"),axis.title=element_text(size=14, face="bold")) +
  scale_y_continuous(labels=scales::percent)

print(7)
pq8 <- ggplot(q10 %>% filter(ecpm_bin<1.21, n_available>=1)) +
  geom_line(aes(x=scale_date,y=median_fill, group=as.factor(n_available), colour=as.factor(n_available)),size=1.25) +
  facet_grid(ecpm_bin ~ year_group )+
  xlab("Date")+
  ylab("Median Fill")


pq9 <- ggplot(q9.6 %>% filter(ecpm_bin==0, year_group==2016)) +
  geom_line(aes(x=scale_date,y=median_fill, group=as.factor(has), colour=as.factor(has)),size=1.25) +
  facet_grid(network ~ n_available)+
  xlab("Date")+
  ylab("Median Fill")

#year_group=as.factor(year_group)