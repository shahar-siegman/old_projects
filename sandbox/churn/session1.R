source("../../libraries.R")
loadDF <- function() {
  df <- read.csv("impressionsBySiteByMonthJan2016.csv")
  return(df)
}

preprocess <- function(df, cost_threshold=1000, initial_cost_threshold=0) {
  df <- df %>% filter(cost>initial_cost_threshold) %>% group_by(site) %>%
    mutate(rcpm = 1000*income/imps)
  df$date <- as.Date(paste0(as.character(df$date),"-01"))
  df <- df %>% group_by(site) %>% mutate(last_month=max(date))
  df <- df %>% mutate(month = as.numeric(-floor(difftime(last_month,date,units="days")/28)))
  df <- df %>% group_by(site) %>% mutate(high_cost = mean(cost)>cost_threshold, duration = -min(month),
                                         churn=ifelse(last_month==as.Date("2016-01-01"),F,
                                                      ifelse(last_month <= as.Date("2015-11-01"),T, NA)),
                                         period =ifelse(-month == duration, "start partial",
                                                        ifelse(-month >= duration-3, "first full 3",
                                                               ifelse(- month <= 3 & -month >0, "last full 3",
                                                                      ifelse(month == 0, "end partial", "middle"))))
                                         )
  return(df)
}

filterBlockedUsers <- function(df) {
  bl <- loadBlockedUsers()
  bl$blocked = T
  df <- left_join(df,bl,"user")
  df <- df %>% filter(is.na(blocked)) %>% select(-blocked)
}

analysis1 <- function(df, analysis_column="imps", min.duration=12) {
  df <- df %>%
    filter(duration>=min.duration, high_cost, month>=-min.duration)  %>%
    mutate(scaled_imps = (imps - mean(imps))/sd(imps),
           scaled_cost = (cost - mean(cost))/sd(cost),
           scaled_rcpm = (rcpm - mean(rcpm))/sd(rcpm))

  print(df %>%  group_by(site,churn) %>% summarize() %>% group_by(churn) %>% summarize(nsites=n()))
  dfa18 <- df %>%
    group_by(month, churn) %>%
    summarise(scaled_cost=mean(scaled_cost, na.rm=T), scaled_imps=mean(scaled_imps, na.rm=T), scaled_rcpm=mean(scaled_rcpm, na.rm=T))
  if (analysis_column =="imps")
  {
    ggplot(dfa18 %>% filter(!is.na(churn))) + geom_path(aes(x = month, y = scaled_imps, group = churn, color=!churn),size=2)
  }
  else if (analysis_column =="cost")
  {
      ggplot(dfa18 %>% filter(!is.na(churn))) + geom_path(aes(x = month, y = scaled_cost, group = churn, color=!churn),size=2)
  }
  else # rcpm
  {
    ggplot(dfa18 %>% filter(!is.na(churn))) + geom_path(aes(x = month, y = scaled_rcpm, group = churn, color=!churn),size=2)
  }
}

analysis2 <- function(df, analysis_column="cost") {
  # df %>% group_by(site) %>% filter(high_cost) %>% summarise(cost=sum(cost)) %>% `[[`("cost") %>% quantile(seq(0,1,0.1))
#   0%         10%         20%         30%         40%         50%         60%         70%         80%
#   1005.615    1573.197    2444.892    3869.107    6175.935    9859.394   15764.811   26630.324   52671.230
#   90%        100%
#   115435.070 2033629.724
  df <- preprocess(df,500,50)
  df <- filter(df,high_cost)
  analysis1(df, analysis_column)
}


analysis3 <- function(df) {
  df <- df %>%
    filter(duration >=6, duration <=18 , !is.na(churn), high_cost) %>% mutate(churn=ifelse(churn,0,1)) %>%
    group_by(site, period, churn) %>% summarise(imps=mean(imps), cost=mean(cost))
  df <- df %>%
    group_by(site, churn) %>%
    summarise(cost_1st  = sum(ifelse(period == "first full 3",cost, 0)),
              cost_last = sum(ifelse(period == "last full 3" ,cost,0)),
              imps_1st  = sum(ifelse(period == "first full 3",imps, 0)),
              imps_last = sum(ifelse(period == "last full 3" ,imps, 0))) %>%
    mutate(cost_ratio = cost_last/cost_1st, imps_ratio = imps_last/ imps_1st)
}


