source('../libraries.R')
source('./functions.R')
#a1 <- read.csv('performance_by_account_by_week.csv',stringsAsFactors = F)
#a1$date_monday <- as.Date(a1$date_monday)

a2 <- a1 %>%
  group_by(account) %>%
  mutate(max_imps=max(impressions)) %>%
  ungroup() %>%
  arrange(account,desc(date_monday))

a2$is_tail <- findDeadTail(a2,0.05,1000)

a3 <- a2 %>% arrange(account,date_monday) %>% filter(!is_tail) %>%
  group_by(account) %>%
  filter(n()>5) %>%
  mutate(mean3week=lag(rollmean(impressions, 3, NA, align='right'),2),
         account_week=as.double(date_monday - max(date_monday)) %/% 7,
         account_imps_m=as.factor(ceiling(log10(max(impressions)))),
         current_client = max(date_monday) > '2016-12-25') %>%
  filter(account_week >= - 12) %>%
  mutate(alert = ifelse(mean3week*0.35 > impressions, impressions,NA),
         account_has_alert=ifelse(max(alert,na.rm=T)>0,T,F),
         account_letter=substr(account,1,1))


accounts <- a3 %>% group_by(account) %>%
  summarise(maximps=max(impressions)) %>%
  arrange(desc(maximps)) %>% `[[`('account')

a4 <- a3 %>% filter(account %in% accounts[31:60])
p1 <- ggplot(a4) + geom_line(aes(x=account_week,y=impressions, group=account, colour=account)) +
  geom_point(aes(x=account_week, y=is_alert, group=account, colour=account))+
  facet_grid(current_client~account_has_alert, scales="free")+ guides(colour=F)
