source('../../libraries.R')

loadDF3 <- function() {
  df <- read.csv('performance_with_history_mark_yessin_dec.csv')
}

loadDF4 <- function() {
  df <- read.csv('performance_with_history_mark_yessin_jan.csv')
}

preprocess3 <- function(df) {
  df <- preprocess(df)
  df <- df %>%
    #mutate() %>%
    group_by(placement_id, chain, ordinal, tag_name, network, floor_price) %>%
    summarise(served = sum(served),
              impressions = sum(impressions),
              income = sum(income),
#              chain_impressions = sum(chain_impressions),
              cnt = n()
              ) %>%
    mutate(ecpm = 1000 * income /served,
           rcpm = 1000 * income / impressions,
           fill = served / impressions,
           chain_first_network = ifelse(ordinal==0,as.character(network), "")
           ) %>%
    group_by(placement_id, chain) %>%
    mutate(chain_length = max(as.numeric(as.character(ordinal)))+1,
           chain_first_network=max(chain_first_network),
           chain_impressions = max(impressions),
           cum_fill = cumsum(served) / chain_impressions,
           cum_rcpm = 1000 * cumsum(income) / chain_impressions,
           cum_ecpm = cum_rcpm/cum_fill,
           nimps = pmin(impressions, lag(impressions), lag(impressions, 2), lag(impressions,3), na.rm=T)
    ) %>% ungroup()
   return(df)
}

bouquetPlot <- function(df, colorCol="chain_first_network") {
  # assumes df is chain data for a few placements. each placement will appear on a different panel.
  # preprocess3 will aggregate on dates, so recommended to pre-filter for a specific date range.
  df <- preprocess3(df)

  df[[colorCol]] = as.factor(df[[colorCol]])
  df$chain_impressions = log10(df$chain_impressions)
  df$ordinal=as.factor(df$ordinal)

  ggplot(df) + geom_point(aes_string(x="cum_fill", y="cum_rcpm", size="chain_impressions", colour=colorCol, shape="ordinal")) +
    geom_path(aes_string(x="cum_fill", y="cum_rcpm", colour=colorCol,group="chain")) + facet_wrap(~placement_id)
}

timeFlowPlot <- function(df, colorCol="chain_first_network") {
  df <- df %>% preprocess3() %>% filter(ordinal==chain_length-1)

  df[[colorCol]] = as.factor(df[[colorCol]])
  df$chain_impressions = log10(df$chain_impressions)

  df$ordinal=as.factor(df$ordinal)
  df$chain_length = as.factor(df$chain_length)
  df$placement_id = as.factor(df$placement_id)

  ggplot(df) + geom_point(aes_string(x="cum_fill", y="cum_rcpm", size="chain_impressions", colour=colorCol, shape="placement_id")) +
    geom_path(aes_string(x="cum_fill", y="cum_rcpm", colour=colorCol,group="chain")) + facet_wrap(~chain_length)
}