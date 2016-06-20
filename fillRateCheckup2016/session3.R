source("../libraries.R")

#k <- read.csv("performance_including_available_networks_largest.csv", stringsAsFactors = F)
#k$impressions <- as.numeric(k$impressions)
#k$year_mon=as.yearmon(k$date)

k1 <- a1 %>%
  mutate(ecpm_bin = round(2.5*total_ecpm)/2.5) %>%
  group_by(tagid,ecpm_bin,year_mon) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            served=sum(as.numeric(served)),
            revenue=sum(revenue)) %>%
  ungroup() %>%

  #mutate(ecpm_bin = round(2500*revenue/served)/2.5,
  mutate(fill=served/impressions) %>%
  filter(!is.na(ecpm_bin)) %>%
  rename(placement_id=tagid)


# check whether the trends can be explained by a few dominant placements
# urlsTopImps: isolate the placements that are top 5 by impressions on at least one month
urlsTopImps <- k1 %>%
  ddply("year_mon",function(x) mutate(x, myrank=dense_rank(desc(x$impressions)))) %>%
  filter(myrank <=5) %>% `[[`("placement_id") %>% unique()

k3 <- inner_join(k1, data.frame(placement_id=urlsTopImps, stringsAsFactors = F),by="placement_id")

# placementTopFills: narrow down to the top 3 placements by fill in a certain time period
placementTopFills <- k3 %>%
  filter(as.Date(year_mon)>='2014-10-01',as.Date(year_mon)<='2015-02-01') %>%
  ddply("year_mon",function(x) mutate(x, myrank=dense_rank(desc(x$fill)))) %>%
  filter(myrank <=3) %>% `[[`("placement_id") %>% unique()

# k4: top imps placements, grouped together
k4 <- k3 %>%
  group_by(year_mon,ecpm_bin) %>% summarise(impressions=sum(impressions/1000),served=sum(served/1000)) %>%
  ungroup() %>%
  mutate(fill=served/impressions)

# k5: similar to k4, less 27 placements which represent top by fill and imps
k5 <- k3 %>% filter(!placement_id %in% placementTopFills) %>%
  group_by(year_mon,ecpm_bin) %>% summarise(impressions=sum(impressions/1000),served=sum(served/1000)) %>%
  ungroup() %>%
  mutate(fill=served/impressions)

#p1: top-imps placements, line per placement
p1 <- ggplot(k3 )+
  geom_line(aes(x=as.Date(year_mon),y=fill,group=placement_id,colour=placement_id))+
  geom_point(aes(x=as.Date(year_mon),y=fill,colour=placement_id), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")

# p2: the ecpm bins, top-imps placements only
p2 <- ggplot(k4 %>% filter(ecpm_bin<1.21))+
  geom_line(aes(x=as.Date(year_mon),y=fill,group=ecpm_bin, colour=as.factor(ecpm_bin)))+
  geom_point(aes(x=as.Date(year_mon),y=fill, colour=as.factor(ecpm_bin)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")

# p3: the ecpm bins, top-imps placements without top-fill placements
p3 <- ggplot(k5 %>% filter(ecpm_bin<1.21))+
  geom_line(aes(x=as.Date(year_mon),y=fill,group=ecpm_bin, colour=as.factor(ecpm_bin)))+
  geom_point(aes(x=as.Date(year_mon),y=fill, colour=as.factor(ecpm_bin)), size=2.5)+
  timePlotFormat()+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")+
  ylab("Fill")

