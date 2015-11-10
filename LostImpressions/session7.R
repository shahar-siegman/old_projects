currdir = 'C:/Shahar/Projects/LostImpressions/'
source('C:/Shahar/Projects/libraries.R')
runSession7 <- function() {
  rawDF <- read.csv(paste0(currdir,'experiment_data_chainlevel.csv'))
  rawDF <- rawDF %>%
    filter(!(placement_id %in% c("203047dd1929e08684f45771d064466c", "5af6afe59f7bbb77b82fff5d388f8073"))) %>%
    filter(nchar(as.character(mobile_chain))<=3) %>%
    arrange(placement_id,nondescript_chain,date)
  a <- session7Plots(rawDF)
  return(a)
}
#    filter(placement_id  == "cbfd0f7b2f0c9a88093862f041c72407") %>%


session7Plots <- function(DF) {
  # start with plotting the returns at the chain level. how well can we induce?
  DF$mobile_fill <- DF$true_mobile_served / DF$true_mobile_imps
  DF$mobile_kfill <- DF$mobile_kserved / DF$mobile_kimpressions
  DF <- ddply(DF, c("placement_id","nondescript_chain"), function(df) mutate(df, mobile_lag_fill = lag(mobile_fill)))
  DF <- ddply(DF, c("placement_id","nondescript_chain"), function(df) mutate(df, mobile_lag_kfill = lag(mobile_kfill)))
  DF$mobile_fill_ret <- DF$mobile_fill / DF$mobile_lag_fill - 1
  DF$mobile_kfill_ret <- DF$mobile_kfill / DF$mobile_lag_kfill - 1

  # nifty filtering of small chains
  DF <- ddply(DF,c("placement_id","nondescript_chain"),filt)
  DF$first_mobile_tag <- substr(DF$mobile_chain,1,1)

  p1 <- ggplot(DF) +
    geom_line(aes(x=date,y=mobile_fill_ret,group=nondescript_chain,color=)) +
    facet_wrap(~placement_id) +
    coord_cartesian(ylim=c(-1,1))

  p2 <- ggplot(DF) +
    geom_line(aes(x=date,y=mobile_fill_ret,group=nondescript_chain,color=placement_id)) +
    facet_wrap(~first_mobile_tag) +
    coord_cartesian(ylim=c(-1,1))
  print(p2)
  # pretty much all over. Let's quantify
#   b <- acast(DF, date ~ nondescript_chain,value.var="mobile_fill_ret") # library(reshap2)
#   c<-cor(b,use="pairwise")

  # correlation matrix is noisy. let's try anyway
  1
  2

  return(DF)
}


filt <- function(df) {
  if(sum(df$true_mobile_served)<100)
    return(df[0,])
  else
    return(df)
  }