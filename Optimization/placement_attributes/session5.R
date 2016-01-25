library(hash)
GroupByWithRollup(df,factor1,factor2) {
  h <- hash()
  g <- group_by_(df,factor1) %>% summarise(impressions=sum(impressions),served=sum(served))
  keys <- g[[factor1]]
  values <-
  h[["_"]]=hash()
}