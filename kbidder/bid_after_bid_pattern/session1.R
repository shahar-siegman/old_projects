source('../../libraries.R')

a<- read.csv('network_bids_with_uid.csv',stringsAsFactors = F)
a$timestamp_ <- strptime(a$timestamp, '%Y-%m-%d %H:%M:%S')
a1 <- ddply(a, .variables= c("uid"), .fun=function(x) {print(x); x$imp_endtime=max(x$timestamp_); return(x) })
  # group_by(uid,cb) %>%
#  mutate(imp_endtime=max(timestamp_))
