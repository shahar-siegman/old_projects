source("../libraries.R")
#a <- read.csv("placement_historical_performance.csv", stringsAsFactors = F)
#a$date <- as.Date("2014-01-01")+a$performance_date

# b - revenue, served and impressions grouped by month and daily placement floor price
b <- a %>% filter(revenue>1,is.numeric(floor_price)) %>%
  mutate(year_mon=as.yearmon(date),
         fp_round=round(ifelse(is.na(floor_price),latest_floor_price,floor_price)*2.5)/2.5) %>%
  group_by(year_mon,fp_round) %>%
  summarise(revenue=sum(as.numeric(revenue)), served=sum(as.numeric(served)), imps = sum(as.numeric(impressions))) %>% # as.numeric(.) solves integer overflow
  ungroup() %>%
  mutate(ecpm=1000*revenue/served, fill = served/imps)

# c - revenue, served and impressions grouped by month and daily placement ecpm
c <- a %>% filter(revenue>1,is.numeric(total_ecpm)) %>%
  mutate(year_mon=as.yearmon(date),
         ecpm_round=round(total_ecpm*2.5)/2.5) %>%
  group_by(year_mon,ecpm_round) %>%
  summarise(revenue=sum(as.numeric(revenue)), served=sum(as.numeric(served)), imps = sum(as.numeric(impressions))) %>% # as.numeric(.) solves integer overflow
  group_by(year_mon) %>% mutate(relative_imps=imps/sum(imps)) %>%
  ungroup() %>%
  mutate(fill = served/imps)


# d - combine with house impression statistics at the placement level
#d1 <- read.csv("house_imps_by_placement.csv",stringsAsFactors = F)
d1$date <- as.Date(d1$date)
a1 <- a %>% filter(date >= "2015-06-01") %>% rename(placement_id=tagid)

a1 <- left_join(a1, d1, by=c("placement_id", "date"))
print(paste(c(nrow(a1), sum(is.na(a1$house_imps)))))
# ecpm by floor price, cross section of March across 3 years - no surprises.
p1 <- ggplot(b %>% filter(year_mon %in% as.yearmon(c("2014-03","2015-03","2016-03")))) +
  geom_line(aes(x=fp_round,y=ecpm,group=year_mon,colour=as.factor(year_mon)))

# fill timelines by category
p2 <- ggplot(c %>% filter(ecpm_round <=5, ecpm_round >=0.4)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=ecpm_round))

# impression distribution by ecpm, over time
p3 <- ggplot(c %>% mutate(ecpm_ceil=pmin(1.2, ecpm_round)) %>% group_by(year_mon,ecpm_ceil) %>% summarise(relative_imps=sum(relative_imps))) +
  geom_line(aes(x=year_mon,y=relative_imps,group=ecpm_ceil,colour=as.factor(ecpm_ceil)),size=2) +
  geom_point(aes(x=year_mon,y=relative_imps,group=ecpm_ceil,colour=as.factor(ecpm_ceil)),size=2.5)

# p4 through p6 - fill timeline by category, broken into 3 eCPM ranges.
p4 <- ggplot(c %>% filter(ecpm_round <=1.21)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)

p5 <- ggplot(c %>% filter(ecpm_round >= 1.19, ecpm_round <= 2.41)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)

p6 <- ggplot(c %>% filter(ecpm_round >= 2.39, ecpm_round <= 3.61)) +
  geom_line(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=year_mon,y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)



