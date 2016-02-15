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
    mutate(chain_impressions = ifelse(ordinal==0,impressions,0)) %>%
    group_by(placement_id, chain, ordinal, tag_name, network, floor_price) %>%
    summarise(served = sum(served),
              impressions = sum(impressions),
              income = sum(income),
              chain_impressions = sum(chain_impressions),
              cnt = n()
              ) %>%
    mutate(ecpm = 1000 * income /served,
           rcpm = 1000 * income / impressions,
           fill = served / impressions
           ) %>%
    group_by(placement_id, chain) %>%
    mutate(chain_length = max(as.numeric(as.character(ordinal)))+1,
           chain_impressions = max(chain_impressions),
           cum_fill = cumsum(served) / chain_impressions,
           cum_rcpm = cumsum(rcpm),
           nimps = pmin(impressions, lag(impressions), lag(impressions, 2), lag(impressions,3), na.rm=T)
    ) %>% ungroup()
   return(df)
}

bouquetPlot <- function(df) {
  # need df after preprocess3
  if ("highlight" %in% names(df)) {
    colorCol="highlight"
    df$highlight=as.factor(df$highlight)
  }
  else
  {
    colorCol="chain"
    df$chain = as.factor(df$chain)
  }
  df$chain_impressions = log(df$chain_impressions)
  df$ordinal=as.factor(df$ordinal)

  ggplot(df) + geom_point(aes_string(x="cum_fill", y="cum_rcpm", size="chain_impressions", colour=colorCol, shape="ordinal")) +
    geom_path(aes_string(x="cum_fill", y="cum_rcpm", colour=colorCol),group=chain) + facet_wrap(~placement_id)
}