session5 <- function()
{

}

countChains <- function(df) {
tot <- df %>%
  filter(as.Date(date_joined) <= "2015-10-07", !is.na(ordinal)) %>%
  preprocess3() %>%
  group_by(placement_id, chain_length) %>% summarise(impressions = sum(chain_impressions), served=sum(served), n_chains=n_distinct(chain)) %>%
  group_by(placement_id) %>% mutate(impressions=sum(impressions), served=sum(served), placement_chains=sum(n_chains)) %>% ungroup() %>%
  arrange(-placement_chains, placement_id) %>% dcast(placement_id ~ n_chains)
}

prepareForBouquet <- function(df, placementId) {
  # placementId = "66efa8ef06355f0c70da35c246b2e07d"
  df %>% filter(placement_id == placementId, chain!="") %>%
    mutate(day=as.numeric(as.Date(date_joined)-as.Date("2015-09-01")), placement_id = floor(day/7))
}