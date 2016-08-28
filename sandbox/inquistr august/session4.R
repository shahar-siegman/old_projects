
a7 <- a2 %>% filter(is_leading_chain,
              date %in% (as.Date("2016-08-01")+0:8),
              chain_length>2,
              place==chain_length) %>%
  mutate(placement_id=as.character(placement_id))

b3 <- b1 %>% filter(date %in% (as.Date("2016-08-01")+0:8)) %>%
  select(-week)

a8 <- left_join(a7,b3,by=c("placement_id","date")) # week is redundant but since exists, avoid duplication

a9 <- a8 %>% mutate(chain_ecpm=chain_cum_rcpm/chain_cum_fill)  %>%
  filter(chain_allocation>0.1, chain_ecpm<floor_price )

a9 <- a9 %>%
  group_by(placement_id, chain_codes) %>%
  mutate(day_num=row_number(date)) %>%
  ungroup() %>%
  select(-place,-tag_code,-tag_ecpm, -week, -tag_network, -is_leading_chain, -lead_tag_network) %>%
  mutate(loss=impressions*chain_cum_fill*(floor_price-chain_ecpm)/1000)