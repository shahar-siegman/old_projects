runOfOnes <- function(df,colName) {
  x <- df[[colName]]
  z <- length(x)
  y <- rep(0,z)
  y[1] <- ifelse(x[1]==1,1,0)

  if (z>=2)
    for (i in 2:length(x))
      y[i] <- ifelse(x[i]==1,y[i-1] + 1,0)

  df$cum_good <- y
}
runOfOnesS <- function(q) {
  x <- q$good_day
  z <- length(x)
  y <- rep(0,z)
  y[1] <- ifelse(x[1]==1,1,0)
  prevCleanUrl <- q$clean_url[1]
  for (i in 2:nrow(q))
  {
    cleanUrl=q$clean_url[i]
    if (cleanUrl==prevCleanUrl && x[i]==1)
      y[i] <- y[i-1]+1
    else
      y[i] <- x[i]
    prevCleanUrl=cleanUrl
  }

  q$cum_good <- y
  return(q)
}



q11 <- q %>% arrange(clean_url,date) %>%
  group_by(clean_url) %>%
  mutate(date_step=date-lag(date, default=0),
         fill=served/impressions,
         good_day=ifelse(fill>0.05 & impressions>5000 & date_step==1,1,0)) %>%
  ungroup()

#q12 <- q11 %>% runOfOnesS()
print(1)
q13 <- q12 %>%
  mutate(qualify=ifelse(cum_good>5,1,0),year_mon=as.yearmon(date)) %>%
  arrange(clean_url,date) %>%
  group_by(clean_url) %>%
  filter(n()>=8, !is.na(revenue), !is.na(served))
print(2)
q13 <- q13 %>%
  mutate(revenue7=rollmean(revenue,7,fill="extend", align="center"),
         served7=rollmean(served,7,fill="extend", align="center"))
print(3)
q13 <- q13 %>%
    mutate(ecpm_bin=round(2500*revenue7/served7)/2.5,
           ecpm_bin=ifelse(is.na(ecpm_bin),-1,ecpm_bin),
           ecpm_bin=ifelse(ecpm_bin>2,2,ecpm_bin),
           fill=sum(as.numeric(served))/sum(as.numeric(impressions)))
print(3)
q13 <- q13 %>%
  group_by(qualify,year_mon,ecpm_bin) %>%
  summarise(impressions=sum(as.numeric(impressions)),
            fill=sum(as.numeric(served))/sum(as.numeric(impressions)),
            revenue=sum(revenue))
print(3)
pq12 <- ggplot(q13 %>% filter(ecpm_bin >-0.01),aes(x=as.Date(year_mon),y=fill,group=qualify, colour=as.factor(qualify))) +
  geom_line(size=2)+
  geom_smooth(se=F)+
  facet_wrap(~ecpm_bin)+
  scale_y_continuous(labels=scales::percent)+
  xlab("Date")

q14 <- q13 %>% group_by(year_mon) %>%
  mutate(share_total_monthly_revenue=revenue/sum(revenue),
         share_total_monthly_imps=impressions/sum(impressions)) %>%
  group_by(year_mon, ecpm_bin) %>%
  mutate(share_bin_monthly_revenue=revenue/sum(revenue),
         share_bin_monthly_imps=revenue/sum(revenue)) %>%
  ungroup() %>%
  filter(qualify==1)

pq13 <- ggplot(q14 %>% filter(ecpm_bin <2.01))+
  geom_line(aes(x=as.Date(year_mon),y=share_total_monthly_revenue,group=qualify,colour='a'),size=2)+
  geom_smooth(aes(x=as.Date(year_mon),y=share_total_monthly_revenue,group=qualify,colour='a'),se=F)+
  geom_line(aes(x=as.Date(year_mon),y=share_bin_monthly_revenue,group=qualify,colour='b'),size=2)+
  geom_smooth(aes(x=as.Date(year_mon),y=share_bin_monthly_revenue,group=qualify,colour='b'),se=F)+
  facet_wrap(~ecpm_bin)+
  scale_y_continuous(labels=scales::percent)+  xlab("Date")+
  ylab("Share")+
  scale_colour_manual(name = 'Share of',
                      values= c('a'=hcl(195,100,65), 'b'=hcl(15,100,65)),
                      labels = c('Total revenue','Bin revenue'))
