#source('session1.R')

# rank the chain by their value to komoona

d1 <- a4 %>% filter(place==chain_length) %>% left_join(b1, by=c("placement_id","date","week"))

d2 <- d1 %>% mutate(komoona_rcpm=chain_cum_rcpm-floor_price*chain_cum_fill) %>%
  group_by(placement_id, date) %>%
  mutate(chain_daily_rank=row_number(desc(komoona_rcpm))) %>%
  arrange(placement_id,date,chain_codes) %>%
  group_by(placement_id,chain_codes) %>%
  mutate(lead_rank=lead(chain_daily_rank)) %>%
  ungroup()