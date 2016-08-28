source('../../libraries.R')
a1 <- a %>% group_by(uid,domain,date) %>%
  summarise(imps=n(),
            distinct_placement=n_distinct(placement_id))

a2 <- a1 %>% group_by(distinct_placement) %>% summarise(n_uid=n())

a3 <- a %>% group_by(uid,domain) %>%
  summarise(imps=n(),distinct_date=n_distinct(date)) %>%
  group_by(distinct_date) %>% summarise(imps=sum(imps),n_uid_dates=n())