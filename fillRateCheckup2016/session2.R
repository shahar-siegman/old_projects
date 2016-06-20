source("../libraries.R")

g <- read.csv("placement_historical_performance_with_tag_url.csv", stringsAsFactors = F, sep=";")
g$date = g$performance_date_date

# g0 - group by url before binning by ecpm
g0 <- g %>% group_by(clean_url,date) %>%
  summarise(impressions=sum(impressions),
            served=sum(served),
            cost=sum(cost),
            profit=sum(profit)) %>%
  ungroup() %>%
  mutate(fill=served/impressions,
         revenue=cost+profit,
         client_ecpm=1000*cost/served,
         total_ecpm =1000*revenue/served)

g1 <- g0 %>% filter(revenue>1) %>%
  mutate(year_mon=as.yearmon(date),
         ecpm_round=round(total_ecpm*2.5)/2.5)


# b2 - revenue, served and impressions grouped by month and daily placement ecpm
h2 <- g1 %>%
  group_by(year_mon,ecpm_round) %>%
  summarise(revenue=sum(as.numeric(revenue)), served=sum(as.numeric(served)), imps = sum(as.numeric(impressions))) %>% # as.numeric(.) solves integer overflow
  group_by(year_mon) %>% mutate(relative_imps=imps/sum(imps)) %>%
  ungroup() %>%
  mutate(fill = served/imps)

# p4 through p6 - fill timeline by category, broken into 3 eCPM ranges.
ph4 <- ggplot(h2 %>% filter(ecpm_round <=1.21)) +
  geom_line(aes(x=as.Date(year_mon),y=fill,group=ecpm_round,colour=as.factor(ecpm_round)),size=2)+
  geom_point(aes(x=as.Date(year_mon),y=fill,group=ecpm_round,colour=as.factor(ecpm_round)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")+
  ecpmCeilCategories(F)