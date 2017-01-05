source('../libraries.R')


# a1 <- read.csv('performance_by_account_by_month.csv',stringsAsFactors = F)

a2 <- a1 %>%
  mutate(ym = as.yearmon(paste0(year_,'-',month_))) %>%
  group_by(account) %>%
  mutate(max_imps=max(impressions)) %>%
  ungroup() %>%
  filter(max_imps>500000, year_ < 2017) %>%
  arrange(account, desc(ym))

a2$is_tail = findDeadTail(a2,0.1)

a2 <- a2 %>%  arrange(account, year_, month_) %>% filter(!is_tail)
a2$is_pre = findDeadTail(a2,0.01)
a2 <- a2 %>% filter(!is_pre)
maxImpRank <- data.frame(max_imps = unique(a2$max_imps))
maxImpRank <- maxImpRank %>% mutate(max_imp_rank = ntile(max_imps,5))

a3 <- a2 %>% group_by(account) %>%
  mutate(imp_rank=percent_rank(impressions),
         min_ym = min(ym),
         max_ym = max(ym)) %>%
  ungroup() %>%
  mutate(month_ord=round(12*(ym-max_ym)),
         is_churn = max_ym < 2016+10/12,
         account_year = as.factor(floor(as.double(min_ym)))) %>%
  left_join(maxImpRank, by='max_imps')

a3<- a3 %>% mutate(max_imp_group=max_imp_rank)
a4 <- a3 %>% group_by(max_imp_group, account_year, is_churn, month_ord) %>%
  summarise(imp_rank_mean=mean(imp_rank),
            imp_rank_median=median(imp_rank))

p1 <- ggplot(a3) + geom_line(aes(x=month_ord, y=imp_rank_median, group=account, colour=account)) +
  facet_wrap(~max_imp_group) + guides(colour=F)

p2 <- ggplot(a4 %>% filter(month_ord>=-12)) + geom_line(aes(x=month_ord, y=imp_rank_median, group=account_year, colour = account_year)) +
  facet_grid(max_imp_group ~ is_churn)

p3 <- ggplot(a4 %>% filter(month_ord>=-12)) + geom_line(aes(x=month_ord, y=imp_rank_mean, group=account_year, colour = account_year)) +
  facet_grid(max_imp_group ~ is_churn)

