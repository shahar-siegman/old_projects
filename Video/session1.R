library(ggplot2)
currdir <- 'C:/Shahar/Projects/Video/'
DF <- read.csv(paste0(currdir,'video_placement_data_redshift.csv'),sep="\t")
ggplot(DF)+geom_density(aes(x=ad_start_time-tag_start_time,fill=ua_browser), alpha=0.5) + facet_wrap(~placement_id)


