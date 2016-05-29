source("../libraries.R")
#a <- read.csv("placement_historical_performance.csv", stringsAsFactors = F)
a$date <- as.Date("2014-01-01")+a$performance_date
a1 <- a %>% filter(revenue>1,is.numeric(floor_price),date>as.Date("2016-03-01"), date<as.Date("2016-04-01"))
revByFloorPrice1 <- a1 %>% mutate(fp_round=round(floor_price*10)) %>%
  select(fp_round,revenue) %>% rbind(data.frame(fp_round=seq(0,3,0.1),revenue=0)) %>%
  group_by(fp_round) %>% summarise(revenue=sum(revenue)) %>%
  mutate(fp_round=fp_round/10) %>%
  ungroup() %>% filter(!is.na(fp_round)) %>% mutate(revenue=revenue/sum(revenue))

a2 <- a %>% filter(revenue>1,is.numeric(floor_price),date>as.Date("2015-03-01"), date<as.Date("2015-04-01"))
revByFloorPrice2 <- a2 %>% mutate(fp_round=round(floor_price*10)) %>%
  select(fp_round,revenue) %>% rbind(data.frame(fp_round=seq(0,3,0.1),revenue=0)) %>%
  group_by(fp_round) %>% summarise(revenue=sum(revenue)) %>%
  mutate(fp_round=fp_round/10) %>%
  ungroup() %>% filter(!is.na(fp_round)) %>% mutate(revenue=revenue/sum(revenue))
revByFP <- rbind(revByFloorPrice1 %>% mutate(period=2), revByFloorPrice2 %>% mutate(period=1)) %>%
  mutate(period=as.factor(period))
p <- ggplot(revByFP) + geom_line(aes(x=fp_round, y=revenue, color=period),alpha=0.5) +
    coord_cartesian(xlim=c(0,3))