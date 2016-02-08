clusterFloorPrices <- function(df) {
  floorPriceList <- df %>% group_by(tag_name, floor_price) %>% summarise() %>% ungroup() %>% select(floor_price)
  for (i in 2:10) {
    centers <- quantile(floorPriceList$floor_price, seq(1,i)/(i+1))
    clusters <- kmeans(floorPriceList, centers)
    goodness <- clusters$tot.withinss/clusters$totss
    print(paste0("i= ",i,", goodness= ",goodness))
    if (goodness < 0.1)
      break

  }
  floorPriceList$fp_cluster <- clusters$cluster
  floorPriceList <- floorPriceList %>% group_by(floor_price, fp_cluster) %>% summarise() %>% ungroup
  return(floorPriceList)
}

checkClusterFloorPrice <- function(df) {
  cl <- clusterFloorPrices(df2) %>% arrange(floor_price)
  ggplot(cl) + geom_histogram(aes(x=floor_price,fill=as.factor(fp_cluster)),binwidth=0.1)
}

preprocess2 <- function(df) {
  fp_clusters <- clusterFloorPrices(df)
  df <- left_join(df, fp_clusters, by = "floor_price")
  fp_clusters <- fp_clusters %>% rename(prev_fp=floor_price, prev_fp_cluster=fp_cluster)
  df <- left_join(df, fp_clusters, by = "prev_fp")
  df$prev_network_cluster <- paste0(df$prev_network,df$prev_fp_cluster)
  df$network_cluster <- paste0(df$network, df$fp_cluster)
  return(df)
}

preparePhiData <- function(df) {
df <- preprocess2(df)
df <- df %>%
  filter(as.Date(date_joined)>="2015-09-30", as.numeric(as.character(ordinal)) <= 1) %>%
  group_by(network_cluster,prev_network_cluster,ordinal) %>%
  summarise(impressions=sum(impressions),served=sum(served)) %>%
  mutate(fill = served/impressions)
df <- left_join(df,
                df %>% ungroup() %>%
                  filter(ordinal==0) %>%
                  select(network_cluster,fill) %>%
                  rename(prev_network_cluster = network_cluster, prev_fill=fill),
                by="prev_network_cluster")
df <- left_join(df,
                df %>% ungroup() %>%
                  filter(ordinal==0) %>%
                  select(network_cluster,fill) %>%
                  rename(root_fill=fill),
                by="network_cluster")
df <- df %>% mutate(x=root_fill*(1 - prev_fill))
}

plotPhiData <- function(df) {
  df <- preparePhiData(df)
  ggplot(df,aes(x=x, y=fill)) + geom_point() + geom_smooth(method=lm)
}

