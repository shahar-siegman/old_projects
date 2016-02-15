session5 <- function()
{

}

extrapolateFloorPrice(df, case)
{
  factors <- c(names(case),"floor_price_20")
  k <- LeaveOneOutFullTest(df,)
}

tot <- df %>% filter(as.Date(date_joined) <= "2015-10-07", !is.na(ordinal)) %>% preprocess3() %>% group_by(placement_id, chain_length) %>% summarise(impressions = sum(chain_impressions), served=sum(served), n_chains=n_distinct(chain)) %>% group_by(placement_id) %>% mutate(impressions=sum(impressions), served=sum(served), placement_chains=sum(n_chains)) %>% ungroup() %>% arrange(-placement_chains, placement_id) %>% dcast(placement_id ~ n_chains)