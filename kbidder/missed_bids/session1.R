source('../../libraries.R')

a <- read.csv('timing_analysis_Oct4.csv',stringsAsFactors = F)
b <- read.csv('placement_estimated_delay.csv',stringsAsFactors = F)

a1 <- a %>% inner_join(b,by='placement_id')