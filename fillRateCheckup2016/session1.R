source("../libraries.R")
#a <- read.csv("placement_historical_performance.csv", stringsAsFactors = F)
#a$date <- as.Date("2014-01-01")+a$performance_date

a <- read.csv("placement_performance_since_2014-01_with_tagurl.csv", sep=";", stringsAsFactors = F)
a$date <- a$performance_date_date

timePlotFormat <- function()
{
  theme(axis.text=element_text(size=18,face="bold"),
        axis.title=element_text(size=18,face="bold"),
        panel.grid.major.x=element_line(colour="grey",linetype=2, size=1.5))
}

ecpmCeilCategories <- function(ceil=T)
{
  b <- c("0-20¢","20¢-60¢","60¢-$1.00")
  if (ceil)
    b <- c(b,"> $1.00")
  else
    b <- c(b,"$1.00-$1.40")
  return( scale_colour_discrete(name="eCPM category\n(dollars)" ,labels=b))
}
print(1)
# a1 - a clean version of a
a1 <- a %>% filter(revenue>1,is.numeric(floor_price)) %>%
  mutate(year_mon=as.yearmon(date),
         fp_round=round(ifelse(is.na(floor_price),latest_floor_price,floor_price)*2.5)/2.5,
         ecpm_round=round(total_ecpm*2.5)/2.5)

# b1 - revenue, served and impressions grouped by month and daily placement floor price
b1 <- a1 %>%
  group_by(year_mon,fp_round) %>%
  summarise(revenue=sum(as.numeric(revenue)), served=sum(as.numeric(served)), imps = sum(as.numeric(impressions))) %>% # as.numeric(.) solves integer overflow
  ungroup() %>%
  mutate(ecpm=1000*revenue/served, fill = served/imps)
print(2)
# b2 - revenue, served and impressions grouped by month and daily placement ecpm
b2 <- a1 %>%
  group_by(year_mon,ecpm_round) %>%
  summarise(revenue=sum(as.numeric(revenue)), served=sum(as.numeric(served)), imps = sum(as.numeric(impressions))) %>% # as.numeric(.) solves integer overflow
  group_by(year_mon) %>% mutate(relative_imps=imps/sum(imps)) %>%
  ungroup() %>%
  mutate(fill = served/imps)
print(3)

# d - combine with house impression statistics at the placement level
#houseImps <- read.csv("house_imps_by_placement.csv",stringsAsFactors = F)
#houseImps$date <- as.Date(houseImps$date)
#a2 <- a1 %>% filter(date >= "2015-06-01") %>% rename(placement_id=tagid)

#a2 <- left_join(a2, houseImps, by=c("placement_id", "date"))
# print(paste(c(nrow(a1), sum(is.na(a1$house_imps)))))
b3 <- a2 %>%  mutate(ecpm_ceil=pmin(1.6, ecpm_round)) %>%
  group_by(year_mon,ecpm_ceil) %>%
  summarise(revenue=sum(as.numeric(revenue)),
            served=sum(as.numeric(served)),
            imps = sum(as.numeric(impressions)),
            house_imps=sum(as.numeric(house_imps),na.rm=T)) %>% # as.numeric(.) solves integer overflow
  group_by(year_mon) %>%
  mutate(relative_imps=imps/sum(imps),
         percent_house_imps = house_imps/imps,
         fill = served/imps,
         net_fill = served/(imps-house_imps))
# histogram of skipped imps percent
c1 <- a2 %>% group_by(year_mon,placement_id) %>%
  summarise(imps=sum(as.numeric(impressions)),
            house_imps=sum(as.numeric(house_imps), na.rm=T),
            served=sum(as.numeric(served)),
            revenue=sum(as.numeric(revenue))) %>%
  filter(imps>1000, served>50) %>%
  mutate(percent_house_imps = house_imps/imps,
         percent_house_imps_bins=round(percent_house_imps*25)/25,
         ecpm_ceil=pmin(1.6, round(1000*revenue/served*2.5)/2.5))
c2 <- c1 %>%
  group_by(year_mon,ecpm_ceil, percent_house_imps_bins) %>%
  summarise(n_placements=n(),
            revenue=sum(revenue),
            imps = sum(as.numeric(imps)),
            house_imps=sum(as.numeric(house_imps)),
            fill=sum(as.numeric(served))/sum(as.numeric(imps))) %>%
  filter(revenue>50) %>%
 #  arrange(year_mon, ecpm_ceil, percent_house_imps_bins) %>%
  group_by(year_mon, ecpm_ceil) %>%
  mutate(house_imps_hist=house_imps/sum(house_imps))


p8 <- ggplot(c2 %>% filter(year_mon %in% as.yearmon(c("2015-09", "2015-12","2016-03","2016-05")),
                           ecpm_ceil == 0)) +
  geom_step(aes(x=percent_house_imps_bins,y=house_imps_hist), size=2) +
  facet_wrap(~year_mon)

p9 <- ggplot(c1 %>% group_by(year_mon) %>% summarise(percent_house_imps=sum(house_imps)/sum(imps))) +
  geom_line(aes(x=year_mon, y=percent_house_imps), size=2)+
  geom_point(aes(x=year_mon, y=percent_house_imps), size=2.5)

p7 <- ggplot(b3) +
  geom_line(aes(x=year_mon, y=percent_house_imps, group=ecpm_ceil, colour =as.factor(ecpm_ceil)), size=2)+
  geom_point(aes(x=year_mon, y=percent_house_imps, colour =as.factor(ecpm_ceil)), size=2.5)

# fill and net fill over time by eCPM category, split into 5 eCPM categories.
p4b <- ggplot(b3) +
  geom_line(aes(x=year_mon,y=net_fill,group=ecpm_ceil,colour=as.factor(ecpm_ceil)),size=2)+
  geom_point(aes(x=year_mon,y=fill,group=ecpm_ceil,colour=as.factor(ecpm_ceil)), size=2.5)

# ecpm by floor price, cross section of March across 3 years - no surprises.
p1 <- ggplot(b1 %>% filter(year_mon %in% as.yearmon(c("2014-03","2015-03","2016-03")))) +
  geom_line(aes(x=fp_round,y=ecpm,group=year_mon,colour=as.factor(year_mon)))

# fill timelines by category
p2 <- ggplot(b2 %>% filter(ecpm_round <=5, ecpm_round >=0.4)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=ecpm_round))

# impression distribution by ecpm, over time
p3 <- ggplot(b2 %>% mutate(ecpm_ceil=pmin(1.2, ecpm_round)) %>% group_by(year_mon,ecpm_ceil) %>% summarise(relative_imps=sum(relative_imps))) +
  geom_line(aes(x=as.Date(year_mon),y=relative_imps,group=ecpm_ceil,colour=as.factor(ecpm_ceil)),size=2) +
  geom_point(aes(x=as.Date(year_mon),y=relative_imps,group=ecpm_ceil,colour=as.factor(ecpm_ceil)),size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fraction of impressions")+labs(colour="eCPM category\n(dollars)")+
  ecpmCeilCategories()

# p4 through p6 - fill timeline by category, broken into 3 eCPM ranges.
p4 <- ggplot(b2 %>% filter(ecpm_round <=1.21)) +
  geom_line(aes(x=as.Date(year_mon),y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=as.Date(year_mon),y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")+
  ecpmCeilCategories(F)

p5 <- ggplot(b2 %>% filter(ecpm_round >= 1.19, ecpm_round <= 2.41)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)

p6 <- ggplot(b2 %>% filter(ecpm_round >= 2.39, ecpm_round <= 3.61)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)


