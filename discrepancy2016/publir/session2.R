library(dplyr)
library(ggplot2)
library(stringr)
a <- read.csv("performance_with_history.csv",stringsAsFactors = F) %>%
  filter(!date_joined %in% c('2016-05-02','2016-05-15'))

b <- a %>% arrange(placement_id, date_joined, chain_num_in_day) %>%
  group_by(placement_id, date_joined, chain_num_in_day) %>%
  mutate(next_tag_impressions = lead(impressions),
  tag_lost_imps = impressions-served-next_tag_impressions,
  network=substr(tag_name,1,1))


