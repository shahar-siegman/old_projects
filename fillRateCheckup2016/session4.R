source("../libraries.R")

readQ <- function() {
  q <- read.csv("performance_including_available_networks_largest.csv", stringsAsFactors = F)
  q$impressions <- as.numeric(q$impressions)
  q <- q %>% filter(!is.na(impressions))
  q$year_mon=as.yearmon(q$date)
  q$date=as.Date(q$date)
  return(q)
}

#q <- readQ()

q1 <- q %>%
  group_by(year_mon,clean_url) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            available=last(available_down)) %>%
  mutate(fill=served/impressions,
         ecpm_bin=round(2500*revenue/served)/2.5,
         n_available=ifelse(str_length(available)==0,0,str_count(available,";")+1)) %>%
  filter(impressions>5000, !is.na(ecpm_bin))

q2 <- q1 %>%
  group_by(year_mon,ecpm_bin) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(fill)) %>%
  mutate(fill=served/impressions)


# first, a more correct version of plot p5 from session3. Median fill of all tag_urls that had a revenue of at least $1 in the month
pq1 <- ggplot(q2 %>% filter(ecpm_bin <1.21)) +
  geom_line(aes(x=as.Date(year_mon),y=median_fill,group=ecpm_bin, colour=as.factor(ecpm_bin)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=median_fill, colour=as.factor(ecpm_bin)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Median Fill")+
  ecpmCeilCategories(F)

q3 <- q1 %>% filter(ecpm_bin==0) %>%
  group_by(year_mon,n_available) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(fill))

pq2 <- ggplot(q3) +
  geom_line(aes(x=as.Date(year_mon),y=median_fill,group=n_available, colour=as.factor(n_available)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=median_fill, colour=as.factor(n_available)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")


q4 <- q1 %>% filter(ecpm_bin <=0.81, n_available==1) %>%
  group_by(year_mon,available) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(fill),
            n_urls=n_distinct(clean_url))

pq3 <- ggplot(q4) +
  geom_line(aes(x=as.Date(year_mon),y=median_fill,group=available, colour=as.factor(available)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=median_fill, colour=as.factor(available)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")


pq3r <- ggplot(q4) +
  geom_line(aes(x=as.Date(year_mon), y=revenue, group=available, colour=as.factor(available)), size=2)+
  geom_point(aes(x=as.Date(year_mon), y=revenue, colour=as.factor(available)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::dollar)+
  xlab("Date")+
  ylab("Revenue")

pq3n <- ggplot(q4) +
  geom_line(aes(x=as.Date(year_mon), y=n_urls, group=available, colour=as.factor(available)), size=2)+
  geom_point(aes(x=as.Date(year_mon), y=n_urls, colour=as.factor(available)), size=2.5)+
  timePlotFormat()+
  xlab("Date")+
  ylab("Number of Sites")


q5 <- q1 %>% filter(available=="openx;pubmatic", ecpm_bin<0.81) %>%
  group_by(year_mon,ecpm_bin) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(fill))

pq4 <- ggplot(q5) +
  geom_line(aes(x=as.Date(year_mon),y=median_fill,group=ecpm_bin, colour=as.factor(ecpm_bin)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=median_fill, colour=as.factor(ecpm_bin)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")



q6 <- q1 %>% filter(str_count(available,"openx;pubmatic")==1,n_available<=3, ecpm_bin<0.81) %>%
  group_by(year_mon,available) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue),
            median_fill=median(fill),
            n_urls=n_distinct(clean_url))

pq5 <- ggplot(q6) +
  geom_line(aes(x=as.Date(year_mon),y=median_fill,group=available, colour=as.factor(available)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=median_fill, colour=as.factor(available)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")

pq5r <- ggplot(q6) +
  geom_line(aes(x=as.Date(year_mon),y=revenue, group=available, colour=as.factor(available)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=revenue, colour=as.factor(available)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::dollar)+
  xlab("Date")+
  ylab("Revenue")

pq5n <- ggplot(q6) +
  geom_line(aes(x=as.Date(year_mon),y=n_urls, group=available, colour=as.factor(available)), size=2)+
  geom_point(aes(x=as.Date(year_mon),y=n_urls, colour=as.factor(available)), size=2.5)+
  timePlotFormat()+
  #scale_y_continuous(labels=scales::dollar)+
  xlab("Date")+
  ylab("number of sites")

q7 <- q1 %>%
  group_by(year_mon,n_available) %>%
  summarise(n_url=n_distinct(clean_url)) %>%
  group_by(year_mon) %>%
  mutate(n_url_rel=n_url/sum(n_url), year_qtr=as.yearqtr(year_mon))

pq6 <- ggplot(q7) +
  geom_line(aes(x=n_available,y=n_url_rel, group=year_mon,colour=as.factor(months(year_mon)))) +
  facet_wrap(~year_qtr)