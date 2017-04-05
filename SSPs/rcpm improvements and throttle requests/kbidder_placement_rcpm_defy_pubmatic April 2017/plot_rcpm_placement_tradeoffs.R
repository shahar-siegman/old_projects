source('../../libraries.R')
placement_rcpm_thresholds = seq(0, 0.005,0.001)
a= read.csv('pubmatic_kbidder_placement_rcpms_March30.csv', stringsAsFactors = F)

blacklisted <- a %>% filter(blacklisted=='blacklisted')
not_blacklisted <- a %>% filter(blacklisted=='none')
resultDf = data.frame()

for (thres in placement_rcpm_thresholds) {
  b <- blacklisted %>%
    filter(network_rcpm > thres) %>%
    group_by(domain) %>%
    summarise(impressions =sum(impressions_all_networks),
              revenue = sum(network_revenue),
              rcpm=1000*sum(network_revenue)/sum(impressions_all_networks)) %>%
    mutate(thres=thres)
  resultDf <- rbind(resultDf, b)
}

ref_domains <- not_blacklisted %>% group_by(domain) %>%
  summarise(impressions =sum(impressions_all_networks),
            revenue = sum(network_revenue),
            rcpm=1000*sum(network_revenue)/sum(impressions_all_networks)
            )
bad_domains <- blacklisted %>% group_by(domain) %>%
  summarise(impressions =sum(impressions_all_networks),
            revenue = sum(network_revenue),
            rcpm=1000*sum(network_revenue)/sum(impressions_all_networks)
  )

p <- ggplot()+
  geom_point(data=ref_domains,aes( x=impressions,y=rcpm,fill='blue',colour='blue')) +
  geom_point(data=resultDf,aes( x=impressions,y=rcpm,fill='orange',colour='orange')) +
  geom_line(data= resultDf,aes(x=impressions, y=rcpm,colour='orange',group=domain))
  #scale_x_log10()
p1 <-ggplot()+
  geom_point(data=ref_domains,aes( x=impressions,y=rcpm,fill='blue',colour='blue')) +
  geom_point(data=bad_domains,aes( x=impressions,y=rcpm,fill='orange',colour='orange'))


