w <- seq(5,7)
#pid <- "08050f0ec22de78e21b9fed08c02b115" # #3
pid <- "139affc1ae629092a7d9acd36557429f" # #8
f1 <- a1 %>%
  filter(placement_id==pid,
         #tag_network=="o",
         impressions>100)

f2 <- a4 %>%
  filter(placement_id==pid,
         #tag_network=="e",
         tag_fill_contrib<0.75,
         impressions>100) %>%
  arrange(date,desc(tag_rcpm_contrib))

f3 <- f2 %>%
  filter(tag_network=="e") %>%
  select(chain_codes,tag_code,date,tag_fill_contrib,place) %>%
  group_by(chain_codes,tag_code) %>%
  mutate(fill_diff=tag_fill_contrib-lag(tag_fill_contrib),
         fill_rel_diff=fill_diff/tag_fill_contrib) %>%
  ungroup() %>%
  arrange(tag_code,chain_codes,date)

f4 <- f3 %>%
  filter(!is.na(fill_diff)) %>%
  dcast(date~tag_code, fun.aggregate=mean, value.var="fill_diff") %>%
  select(-date) %>%
  cor(use="pairwise.complete.obs")

f5 <- eigen(f4,T) %>% as.data.frame() %>% mutate(tag_code=dimnames(f4)[[1]]) %>%
  melt()
# ecpms spanned by the tags
pf1 <- ggplot(f1)+geom_histogram(aes(x=tag_ecpm))+facet_wrap(~week)

#rcpm vs. fill, one line per tag, one panel per network
pf2 <- ggplot(f2 %>% filter(week %in% w))+
  geom_path(aes(x=tag_fill_contrib,y=tag_rcpm_contrib,group=tag_code,colour=as.factor(place))) +
  geom_point(aes(x=tag_fill_contrib,y=tag_rcpm_contrib,colour=as.factor(place))) +
  facet_wrap(~tag_network)

# fill vs. date
pf3 <- ggplot(f2 %>% filter(week %in% w))+
  geom_line(aes(x=date,y=tag_fill_contrib,group=tag_code, color=as.factor(place)))+
  scale_x_date()