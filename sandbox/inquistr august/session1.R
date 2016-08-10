source('../../libraries.R')
#a <- read.csv('chain_performance.csv',stringsAsFactors = F)
#a$date <- as.Date(a$date)
a$placement_id <- as.factor(a$placement_id)
# a <- a %>% mutate(tag_network=as.factor(substr(tag_code,1,1)))
a$week <- as.integer(floor( (a$date-min(a$date)) /7))
b1 <- read.csv('floor_prices.csv',stringsAsFactors = F)
b1$date <- as.Date(b1$date)
b1$week <- as.integer(floor( (b1$date-min(b1$date)) /7))


# chain weekly performance - cumulative by tag
a1 <- a %>% group_by(placement_id,date,tag_code) %>%
  mutate(chainImpsForTag=sum(impressions)) %>%
  ungroup() %>%
  mutate(corrected_served=ifelse(impressions==chainImpsForTag,tag_served,round(tag_served/chainImpsForTag*impressions)),
         week=as.integer(floor( (date-min(date)) /7)),
         corrected_income=ifelse(tag_served==0 | is.na(tag_served),0,tag_ecpm*corrected_served/1000)
         ) %>%
  group_by(placement_id,week,chain_codes,place,tag_code) %>%
  summarise(impressions=sum(impressions,na.rm=T),
            tag_served=sum(corrected_served,na.rm=T),
            house=sum(house,na.rm=T),
            tag_ecpm=1000*sum(corrected_income, na.rm=T)/sum(corrected_served, na.rm=T),
            corrected_income=sum(corrected_income)) %>%
  ungroup() %>%
  mutate(tag_network=as.factor(substr(tag_code,1,1))) %>%
  arrange(placement_id,week,chain_codes, place)  %>%
  group_by(placement_id, week, chain_codes) %>%
  mutate(chain_cum_fill=cumsum(tag_served/impressions),
         chain_cum_rcpm=cumsum(1000*corrected_income/impressions),
         place=row_number(place),
         chain_length=n()
         ) %>%
  filter(impressions > 200)

# chain daily performance - cumulative by tag
a4 <- a %>% group_by(placement_id,date,tag_code) %>%
  mutate(chainImpsForTag=sum(impressions)) %>%
  ungroup() %>%
  mutate(corrected_served=ifelse(impressions==chainImpsForTag,tag_served,round(tag_served/chainImpsForTag*impressions)),
         week=as.integer(floor( (date-min(date)) /7)),
         corrected_income=ifelse(tag_served==0 | is.na(tag_served),0,tag_ecpm*corrected_served/1000)
  ) %>%
  mutate(tag_network=as.factor(substr(tag_code,1,1)),
         tag_fill_contrib=corrected_served/impressions,
         tag_rcpm_contrib=1000*corrected_income/impressions) %>%
  arrange(placement_id,date,chain_codes, place)  %>%
  group_by(placement_id,date, chain_codes) %>%
  mutate(chain_cum_fill=cumsum(corrected_served/impressions),
         chain_cum_rcpm=cumsum(1000*corrected_income/impressions),
         place=row_number(place),
         chain_length=n()
  ) %>%
  filter(impressions > 30)




print(1)
a2 <- a1 %>% group_by(placement_id, week, chain_codes) %>%
  summarise(place=0,
            tag_code='',
            impressions=first(impressions),
            tag_served=0,
            house=0,
            tag_ecpm=0,
            corrected_income=0,
            chain_cum_fill=0,
            chain_cum_rcpm=0,
            chain_length=first(chain_length),
            tag_network=NA
            ) %>%
  rbind(a1) %>%
  arrange(placement_id,week,chain_codes, place) %>%
  group_by(placement_id, week, chain_codes) %>%
  mutate(lead_tag_network=lead(tag_network)) %>%
  ungroup

print(2)
p <- list()
bl <- list()
for (i in 1:30) {
  print(i)
  pid = levels(a2$placement_id)[i]
  a3 <- a2 %>% filter(placement_id==pid)
  bl[[i]] <- b1 %>% filter(placement_id==pid)
  p[[i]] <- ggplot() +
    geom_path(aes(x=chain_cum_fill,y=chain_cum_rcpm,group=chain_codes, colour=lead_tag_network), data=a3, size=1.25)+
    geom_point(aes(x=chain_cum_fill,y=chain_cum_rcpm, colour=tag_network), data=a3) +
    geom_abline(aes(slope=floor_price,intercept=0),data=bl[[i]],colour="black",linetype="dotdash", size=1.25)+
    facet_wrap(~week)
}