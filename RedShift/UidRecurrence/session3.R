source('../../libraries.R')
a4 <- a %>% group_by(uid,domain,date) %>%
  summarise(imps=n(),served=sum(serve_count>0, na.rm=T)) %>%
  filter(imps>20) %>%
  mutate(fill=served/imps,
         fill_cat=ifelse(fill<0.003,
                                   1,
                                   ifelse(fill>0.7,
                                          3,
                                          2)
                                   ))

a5 <- a4 %>% group_by(uid,domain,fill_cat) %>%
  summarise(n_day=n(), imps=sum(imps, na.rm=T))

a6 <- a4 %>% group_by(uid,domain) %>%
  mutate(lag_fill_cat=lag(fill_cat)) %>%
  ungroup() %>%
  mutate(score=
           ifelse(lag_fill_cat==fill_cat,
                  1,
                  ifelse(abs(lag_fill_cat-fill_cat)==1,
                         0,
                         -1))
  )

a7 <- a6 %>% group_by(fill_cat,lag_fill_cat) %>%
  summarise(days_cookies_domains=n(),imps=sum(imps),served=sum(served))

a8 <- a %>% group_by(date) %>% summarise(imps=as.numeric(n())) %>% mutate(day=as.numeric(date-min(date)))
p <- ggplot(a8,aes(x=day,y=imps,group=1))+geom_line(size=3)
  geom_smooth(method="nls",formula=y ~ exp(a+b*x)) #+
    #scale_x_date()