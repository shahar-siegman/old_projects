# no highlights in this file

source('../libraries.R')
library(reshape2)
currdir <- 'C:/Shahar/Projects/Video/'
session3load <- function() {
  df <- read.csv("video_chain_discrepancy.csv")
  df$lost_imps <- df$stat1 - (df$served + df$house)
  df$lost_imps_percent <- df$lost_imps/df$stat1
  df$is_valid <- grepl("([A-Za-z]\\d{1,2}:?)+",df$chain, perl=T) & df$stat1 >50
  contains <- function(c) {grepl(c,df$chain,fixed=T)}
  df$is_video <- ifelse(contains("C"),ifelse(contains("f"),"Cf","C"),ifelse(contains("f"),"f","X"))
  df <- left_join(df, df %>% filter(is_valid & is_video != "-") %>%
                    select(placement_id) %>% distinct(placement_id) %>%
                    mutate(is_video_placement=T)) %>%
    mutate(is_video_placement=ifelse(is.na(is_video_placement),F,T))
  return(df)

}

session3historgrams <- function(df) {
  p1 <- ggplot(df %>% filter(is_valid & is_video_placement)) + geom_density(aes(x=lost_imps_percent,fill=is_video), alpha=0.5) +
    facet_wrap(~placement_id) + xlim(0,1)
  p2 <- ggplot(df %>% filter(is_valid  & is_video_placement)) + geom_boxplot(aes(x=1,y=lost_imps_percent,fill=is_video), alpha=0.5) +
      facet_wrap(~placement_id) + ylim(0,1)
}

session3unmelt1 <- function(df) {
  g <- df %>% filter(is_valid & is_video_placement) %>%
    group_by(placement_id, is_video) %>%
    summarise(lost_imps_percent = median(lost_imps_percent)) %>%
    dcast(placement_id ~ is_video, value.var = "lost_imps_percent")
}

session3unmelt2 <- function(df) {
  g <- df %>% filter(is_valid & is_video_placement) %>%
    group_by(placement_id, date, is_video) %>%
    summarise(lost_imps_percent = median(lost_imps_percent)) %>%
    dcast(placement_id + date ~ is_video, value.var = "lost_imps_percent")
}

session3scatter <- function(g) {
  ggplot(g) + geom_point(aes_string(x="X",y="C"), color="green") +
    geom_point(aes_string(x="X",y="f"), color="blue") +
    stat_smooth(aes_string(x="X",y="C"), geom="smooth", method="lm", color="green", se=F) +
    stat_smooth(aes_string(x="X",y="f"), geom="smooth", method="lm", color="blue", se=F)
}