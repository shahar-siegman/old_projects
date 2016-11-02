source('../../libraries.R')

# a <- read.csv('timing_analysis_Oct4.csv',stringsAsFactors = F)
# b <- read.csv('placement_estimated_delay.csv',stringsAsFactors = F)
#
# a1 <- a %>% inner_join(b,by='placement_id')

a <- read.csv('all_kbidder_bids_oct30-0-5_wins_only.csv', stringsAsFactors = F)
b <- read.csv('all_kbidder_placement_names.csv', stringsAsFactors = F)

a1 <- inner_join(a,b, by=c('placement_id'='layoutid'))

a2 <- a1 %>%
  mutate(max_bid_until_expiry=max_bid_suggested_to_timeout,
         improvement_shortly_after_expiry=
           ifelse(max_bid_within_500ms_of_timeout<0.2, 0,
           ifelse(max_bid_until_expiry < 0.2 & max_bid_within_500ms_of_timeout > 0.2,max_bid_within_500ms_of_timeout,
                  ifelse(max_bid_until_expiry > max_bid_within_500ms_of_timeout,0,
                         max_bid_within_500ms_of_timeout-max_bid_until_expiry))),
         max_bid_shortly_after=pmax(max_bid_until_expiry,max_bid_within_500ms_of_timeout),
         improvement_long_after_expiry=
           ifelse(max_bid_shortly_after < 0.2 & max_bid_after_500ms_of_timeout > 0.2,max_bid_after_500ms_of_timeout,
                  ifelse(max_bid_shortly_after > max_bid_after_500ms_of_timeout,0,
                         max_bid_after_500ms_of_timeout-max_bid_shortly_after))
  )

a3 <-a2 %>% mutate(improvement_shortly_after_expiry_bin=pmin(floor(improvement_shortly_after_expiry/0.1)*0.1,10),
                   improvement_long_after_expiry_bin=pmin(floor(improvement_long_after_expiry/0.1)*0.1,10))

a4.until <- a3 %>%
  group_by(placement_id) %>% mutate(n_imps=n()) %>%
  group_by(placement_id,name,estimated_timeout,improvement_shortly_after_expiry_bin,n_imps)  %>% summarise(count=n()) %>%
  ungroup() %>%
  filter(improvement_shortly_after_expiry_bin!=0) %>%
  group_by(placement_id) %>%
  mutate(relative_count=count/n_imps,
    relative_count_cum=cumsum(count)/n_imps)


a5 <- a4.until %>%
  group_by(placement_id,name,estimated_timeout) %>%
  summarise(improved_impression_count=sum(relative_count),
            average_improvement=sum(relative_count*improvement_shortly_after_expiry_bin)) %>%
  mutate(average_improvement=average_improvement/improved_impression_count)

plot.bid.distrib <- function(placement_num) {
  placements <- unique(a2$placement_id)
  a3 <- a2 %>% filter(placement_id==placements[placement_num])
  print(a2$name[1])
  ggplot(a3)+geom_histogram(aes(x=improvement_until_expiry),fill="blue",alpha=0.4,binwidth=0.1)+
    geom_histogram(aes(x=improvement_after_expiry),fill="green",alpha=0.2,binwidth=0.1) +
    #geom_density(aes(x=max_bid_after_timeout,y=..density..),colour="black")+
    coord_cartesian(xlim=c(0,1))
}

plot.bins <- function(placement_num) {
  placements <- unique(a4.until$placement_id)
  a5 <- a4.until %>% filter(placement_id==placements[placement_num], improvement_shortly_after_expiry_bin>0)
  print(a5$name[1])
  ggplot(a5)+geom_bar(aes(x=improvement_shortly_after_expiry_bin,y=relative_count_cum),stat="identity",fill="blue")+
    scale_y_continuous(labels=percent)+
    scale_x_continuous(breaks=seq(0,10,0.4))
}

plot.after.bins <- function(placement_num) {
  placements <- unique(a4.after$placement_id)
  a5 <- a4.after %>% filter(placement_id==placements[placement_num], improvement_after_expiry_bin>0)
  print(a5$name[1])
  ggplot(a5)+geom_bar(aes(x=improvement_after_expiry_bin,y=relative_count_cum),stat="identity",fill="green")+
    scale_y_continuous(labels=percent)
}

# bid_improvement_to_bins <- function(placement_num) {
#   placements <- unique(a2$placement_id)
#   a3 <- a2 %>% filter(placement_id==placements[placement_num])
#
# }