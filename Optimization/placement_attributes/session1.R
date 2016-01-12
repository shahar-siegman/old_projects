source('../../libraries.R')
require(scales)
loadDF1 <- function() {
  df <- read.csv('performance_with_history_20_placements.csv')
}

loadDF2 <- function() {
  #df <- read.csv('performance_with_history_280_placements.csv')
  df <- read.csv('performance_with_history_280_september.csv')
}

list1 <- c(x="date_joined", color="network", group="ordinal", facet="chain")
list2 <- c(x="date_joined", group="ordinal", facet="placement_id")
list3 <- c(x="floor_price", group="network", facet="placement_id")
list4 <- c(x="floor_price", group="network", facet="placement_id")

session1a <- function(df) {
    if (missing(df))
      df <- loadDF1()
    df <- preprocess(df)
    #p <- list(dotplot(df),  timeplot(df))
    p <- list(myplot(df, c(x="floor_price",y="fill", color="network", facet="placement_id")),
              myplot(df, c(x="date_joined",y="fill", color="network", group= "tag_name", facet="placement_id")) )
    return(p)
}

session1b <- function(df, batch=1) {
  if (missing(df))
    df <- loadDF2()
  df <- preprocess(df)
  df <- placementBatch(df, batch)
  p <- list(myplot(df, c(x="floor_price",y="fill", color="network", facet="placement_id")),
            myplot(df, c(x="date_joined",y="fill", color="network", group= "tag_name", facet="placement_id")) )
  return(p)
}

session1c <- function(df, placementNum=1) {
  if (missing(df))
    df <- loadDF2()
  df <- preprocess(df)
  df <- df %>% filter(as.Date(date_joined) < "2015-12-20")
  df <- placementBatch(df, batch=placementNum, batchSize=1)
  p <- list(myplot(df, c(x="floor_price",y="fill", color="network", facet="chain")),
            myplot(df, c(x="date_joined",y="fill", color="network", group= "tag_name", facet="chain")) )
  return(p)
}

myplot <- function (df, gr) {
  if (is.na(gr["group"]))
    p <- ggplot(df) +
      geom_point(aes_string(x=gr["x"],y=gr["y"],color=gr["color"]))
  else
    p <- ggplot(df) +
      geom_path(aes_string(x=gr["x"],y=gr["y"],color=gr["color"],group=gr["group"]))
  #if (gr["x"]=="date_joined")
  #    p <- p + scale_x_date(breaks=c(min(df$date_joined), max(df$date_joined)), minor_breaks = NULL)
  p <- p + facet_wrap(as.formula(paste("~",gr["facet"])))
  return(p)
}

dotplot <- function(df, color.by="network", facet.by = "placement_id") {
  ggplot(df) + geom_point(aes_string(x="floor_price",y="fill", color=color.by))
}

timeplot <- function(df, color.by="network", facet.by = "placement_id") {
  ggplot(df) + geom_path(aes_string(x="date_joined", y="fill", group = color.by, color=color.by))
}


preprocess <- function(df) {
  df <- df %>% mutate(network = as.factor(substr(tag_name,1,1))) %>%
    sameNetworkOrdinal()
  df <- df %>% mutate(fill = served/impressions,
                ecpm = 1000*income/served,
                rcpm = 1000*income/impressions,
                ordinal = as.factor(ordinal),
                fp_10cent_increment = floor(floor_price*20)/20,
                ordinal_network = paste0(ordinal, network),
                network_ordinal_network= paste0(same_network_ordinal, network)) %>%
    filter(served>0  & impressions > 300 & is.na(is_change))
  return(df)
}

placementBatch <- function(df, batchNum, batchSize=20) {
  placements <- unique(as.character(df$placement_id))
  selectedPlacements <- placements[((batchNum-1)*batchSize)+1 : (batchNum*batchSize)]
  df <- inner_join(df, data_frame(placement_id=selectedPlacements))
  df$placement_id <- as.factor(df$placement_id)
  print(paste0("rows after batch: ", nrow(df)))
  return(df)
}

sameNetworkOrdinal <- function(df) {
  n <- nrow(df)
  ordinal = as.numeric(as.character(df$ordinal))
  #ordinal = df$ordinal
  same_network_ordinal=numeric(n)
  for (i in 1:n)
    if (ordinal[i] > 0) {
    splitChain = unlist(strsplit(as.character(df$chain[i]), ":", fixed=T))
    splitChain = splitChain[1: ordinal[i]]
    network = as.character(df$network[i])
    same_network_ordinal[i] <- sum(substr(splitChain,1,1)==network)
  }
  df$same_network_ordinal <- same_network_ordinal
  return(df)
}

subsetByPlacement <- function(df, num) df %>% filter(placement_id==levels(df$placement_id)[num]) %>% preprocess()