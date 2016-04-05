source('../../libraries.R')
library("L1pack")
getListTagData <- function()
{
  # daily perfromance (mysql) at the tag level (including which chain)
  # for List 2 placements for dates 2016-02-10 to 2016-03-15
  read.csv('list2_placements_tag_performance1.csv', stringsAsFactors = F)
}

preprocess2 <- function(df, min_served_count=500)
{
  df1 <- df %>% mutate(ecpm = 1000*income/served,
                      code=substr(tag_name,1,1),
                      week=as.factor(floor(as.numeric(as.Date(date_joined)-as.Date('2016-02-10'))/7)))

  df1 <- df1 %>% select(placement_id, week, date_joined, floor_price, served, income, tag_name, code, ecpm)
  df1 <- df1 %>% filter(code !="", served>min_served_count)
  return(df1)
}

analysis6 <- function(df)
{
  # df is after preprocess2
  # plot ecpm vs. floor price per network
  ggplot(df) + geom_point(aes(x=floor_price,y=ecpm,colour=week)) +
    geom_abline(slope=1,intercept=0,colour="grey") +
    geom_abline(slope=0.85,intercept=0,colour="blue") +
    facet_wrap(~code)
}

analysis7 <- function(df)
{
  # df is after preprocess2
  # see if yesterday's ecpm is a good prediction
  #df <- df %>% filter(ecpm>1.05*floor_price)
  df <- df %>% arrange(placement_id, floor_price, tag_name, date_joined) %>%
    group_by(placement_id, floor_price, tag_name) %>%
    mutate(ecpm_lag=lag(ecpm)) %>% ungroup()
  ggplot(df) +  geom_point(aes(x=ecpm_lag,y=ecpm,colour=week)) +
    geom_abline(slope=1,intercept=0,colour="grey") + facet_wrap(~code)
}

fitEcpmByNetwork <- function()
{
  # fits a few variants of linear models by network
  df <- getListTagData()
  df <- preprocess2(df)
  networks <- "ejoptx"
  nnet <- str_length(networks)
  netmodels <- data.frame()
  for (i in 1:nnet) {
    network <- substr(networks,i,i)
    data <- df %>% filter(code==network)
    currentLm <- lm(ecpm ~ floor_price + 0, data)
    currentAd <- lad(ecpm ~ floor_price + 0, data)
    # find other key statistics: mode and median
    currentMode <- Mode(data$ecpm/data$floor_price)
    currentMedian <- median(data$ecpm/data$floor_price)
    netmodels <- rbind(netmodels,data.frame(
      network=network,
      least_squares = currentLm$coefficients[1],
      least_abs = currentAd$coefficients[1],
      abs_median_resid = median(abs(currentAd$residuals)),
      mode = currentMode,
      median=currentMedian))
  }
  rownames(netmodels) <- NULL
  return(netmodels)

}

Mode <- function(x) {
  # statistical mode (most common single entry in sample)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

ecpmFloorPriceCoeffs <- function()
{
  # The Results of fitEcpmByNetwork lad
  lines <- "Network, coeff
         e, 1.1813321
         j, 1.0135180
         o, 0.8985693
         p, 0.9902152
         t, 1.0000054
         x, 1.1137289"
  con <- lines %>% textConnection()
  data <- con %>% read.csv()
  con %>% close()
  return(data)

}