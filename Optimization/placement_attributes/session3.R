library(dplyr)
library(reshape2)
source('myImagePlot.R')

transformToQuantiles <- function(df, fp=4,fill=4) {
  df$floor_price_ntile = ntile(df$floor_price,fp)
  df$fill_ntile = ntile(df$fill,fill)
  return(df)
}

analyzeVariance <- function(df, net="e", date="2015-09-01", fp =1) {
  ggplot(df %>% filter(network==net, date_joined==date, floor_price_ntile==fp)) + geom_density(aes(x=fill_ntile,fill=ordinal),alpha=0.3) +
    facet_wrap(~same_network_ordinal_factor)
}

minValidEntries <- function(m,nValid) {
  y <- colSums(!is.na(m))
  colsToRetain <- y > nValid
  return(m[,colsToRetain])
}

normalizedTags <- function(df) {

}

session3 <- function() {
  df2 <- df[df$placement_id == levels(df$placement_id)[22],] %>% preprocess()
  ggplot(df2 %>% arrange(network,tag_name,date_joined, floor_price) %>% filter(floor_price > 0.02)) +geom_path(aes(x=date_joined, y=fill, color=ordinal,group=tag_name), size=1) +geom_point(aes(x=date_joined, y=fill, color=ordinal,shape=network),size=2) +facet_wrap(~floor_price) + ylim(0,0.3)

  df2 %>%
    filter(network=="t", ordinal==0) %>%
    select(network, ordinal, date_joined, floor_price,fp_10cent_increment,fill) %>% dcast(date_joined ~ fp_10cent_increment, fun.aggregate=mean, value.var="fill") %>%
    select(-date_joined) %>%
    cor(use="pairwise.complete.obs") %>%
    minValidEntries(5) %>%
    myImagePlot(zlim=c(-1,1))
}

replaceNAColumnMean <- function(data) {
  for(i in 1:ncol(data)) {
    data[is.na(data[,i]), i] <- mean(data[,i], na.rm = TRUE)
  }
  return(data)
}

preCluster <- function (df) {
  m <- df2 %>%
    mutate(tag_ord_ord=paste(tag_name,ordinal,same_network_ordinal,floor_price,sep="_")) %>%
    dcast(date_joined ~ tag_ord_ord, value.var="fill") %>%
    minValidEntries(30) %>%
    replaceNAColumnMean()
  return(m)
}


clusterK <- function(m,n_cluster) {
  k <- m %>% select(-date_joined) %>% scale() %>% as.matrix() %>% t() %>% kmeans(n_cluster)
  return(k)
}
clusterM <- function(m,n_cluster) {
  # accept a matrix-like data frame, first column "date_joined", all other columns
  # names are tag names
  # m can be obtained by preCluster(df2)
  # consider ?scale the data before running clustering
  # returns a melted matrix, with columns: date, tag, cluster which allow easy plotting
  # with ggplot
  k <- clusterK(m,n_cluster)
  melted_fill <- m %>% melt(id.vars='date_joined', variable.name='tag', value.name = "fill")
  melted_scaled <-  m %>% select(-date_joined) %>% scale() %>% as.data.frame() %>% mutate(date_joined = m$date_joined) %>% melt(id.vars='date_joined', variable.name='tag', value.name = "scaled_fill")
  #melted_scaled$date_joined <- melted_fill$date_joined
  m1 <- inner_join(melted_fill, melted_scaled)
  tagNames <- m %>% select(-date_joined) %>% names()
  m1$cluster <- numeric(nrow(m))
  # match names to clusters
  for (i in 1: n_cluster) {
    tags_in_cluster <- tagNames[k$cluster==i]
    m1$cluster[m1$tag %in% tags_in_cluster] <- i
  }
  return (m1)
}

analysis <- function(m) {
   ggplot(m %>% clusterM(4)) + geom_path(aes(x=date_joined,y=fill,group=tag,color=as.factor(cluster))) + facet_wrap(~cluster)
   #ggplot(m %>% clusterK(4)$

   ggplot(m3 %>% clusterK(4) %>% `[[`("centers") %>% t() %>% as.data.frame() %>% mutate(x=seq(1,nrow(m3))) %>% melt(id.vars="x")) +
     geom_path(aes(x=x,y=value,color=variable))

   m3 %>% clusterM(4) %>% filter(cluster==2) %>%
     dcast(date_joined ~ tag, fun.aggregate=mean, value.var="fill") %>%
     select(-date_joined) %>% cor(use="pairwise.complete.obs") %>%
     myImagePlot(zlim=c(-1,1))
}


