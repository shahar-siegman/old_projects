source('../../libraries.R')

a <- read.csv('50_cookies_july_grouped.csv',stringsAsFactors = F)

a1 <- a %>% filter(uid=='e56b13c36ea3e94c232e87a2ec5e9e4e')


