source('../../libraries.R')
print(1)
a <- read.csv('chain_performance_low_margin_placements.csv',stringsAsFactors = F)
a$date <- as.Date(a$date)
a$placement_id <- as.factor(a$placement_id)
a$week <- as.integer(floor( (a$date-min(a$date)) /7))
a$place <- as.integer(a$place)
a$tag_served <- as.integer(a$tag_served)
a$tag_ecpm <- as.numeric(a$tag_ecpm)
a$tag_fill_contrib <- as.numeric(a$tag_fill_contrib)
a$tag_rcpm_contrib <- as.numeric(a$tag_rcpm_contrib)

a <- a %>% filter(placement_id %in% c('328c2472f5257df2697b5908932619e0',
                                       '371960ca1872757895184fc2a704e76a',
                                       '6e353182dfb4514f2a7924953a0c4d70',
                                       '9ce0d38850bfa5349e46f90e4f46b5b7',
                                       'a28b4de4f73ba41337c87b1a4f739437',
                                       'f4046cd90b36b7fabb61a7c37b2bd933'))


a <- a %>% arrange(placement_id, date, desc(impressions), place)
b1 <- read.csv('floor_prices_low_margin_placements.csv',stringsAsFactors = F)
b1 <- b1 %>% rename(placement_id=tagid, date=date_)
b1$date <- as.Date(b1$date)
b1$week <- as.integer(floor( (b1$date-min(b1$date)) /7))
b1$floor_price=as.numeric(b1$floor_price)
print(2)

a0 <- a %>% group_by(placement_id,date,tag_code) %>%
  mutate(chainImpsForTag=sum(impressions)) %>%
  ungroup() %>%
  mutate(corrected_served=ifelse(impressions==chainImpsForTag,tag_served,round(tag_served/chainImpsForTag*impressions)),
        week=as.integer(floor( (date-min(date)) /7)),
        corrected_income=ifelse(tag_served==0 | is.na(tag_served),0,tag_ecpm*corrected_served/1000),
        tag_network=as.factor(substr(tag_code,1,1)),
        chain_first_tag=substr(chain_codes,1,str_locate(chain_codes,":")[,1]-1),
        chain_first_tag=ifelse(is.na(chain_first_tag),chain_codes,chain_first_tag),
        imps_for_sum=ifelse(place==1,impressions,0))
print(3)
# chain weekly performance - cumulative by tag
a1 <- a0 %>%
  group_by(placement_id,week,chain_codes,place,tag_code,tag_network) %>%
  summarise(impressions=sum(impressions,na.rm=T),
            tag_served=sum(corrected_served,na.rm=T),
            house=sum(house,na.rm=T),
            tag_ecpm=1000*sum(corrected_income, na.rm=T)/sum(corrected_served, na.rm=T),
            corrected_income=sum(corrected_income)) %>%
  ungroup() %>%
  arrange(placement_id,week,chain_codes, place)  %>%
  group_by(placement_id, week, chain_codes) %>%
  mutate(chain_cum_fill=cumsum(tag_served/impressions),
         chain_cum_rcpm=cumsum(1000*corrected_income/impressions),
         place=row_number(place),
         chain_length=n()
         ) %>%
  filter(impressions > 200)
print(4)
# chain daily performance - cumulative by tag
a4 <- a0 %>%
  mutate(tag_fill_contrib=corrected_served/impressions,
         tag_rcpm_contrib=1000*corrected_income/impressions) %>%
  arrange(placement_id,date,chain_codes, place)  %>%
  group_by(placement_id,date, chain_codes) %>%
  mutate(chain_cum_fill=cumsum(corrected_served/impressions),
         chain_cum_rcpm=cumsum(1000*corrected_income/impressions),
         place=row_number(place),
         chain_length=n()
  ) %>%
  filter(impressions > 30)
print(5)
a5 <- a4 %>%
  group_by(placement_id,date,chain_first_tag) %>%
  mutate(is_leading_chain=rank(desc(impressions),ties.method="min")==1,
         extended_chain_imps=sum(imps_for_sum)) %>%
  group_by(placement_id, date) %>%
  mutate(placement_impressions=sum(imps_for_sum,na.rm=T)) %>%
  ungroup() %>%
  mutate(chain_allocation=extended_chain_imps/placement_impressions)
print(6)
a6 <- a5 %>%
  select(placement_id, chain_codes, date, impressions, place, tag_code, tag_served, tag_ecpm,
         week, tag_network, chain_first_tag, chain_cum_fill, chain_cum_rcpm, is_leading_chain, chain_length, chain_allocation)


print(1)
a2 <- a6 %>% group_by(placement_id, chain_codes,date) %>%
  summarise(impressions=first(impressions),
            place=0,
            tag_code='',
            tag_served=0,
            tag_ecpm=0,
            week=first(week),
            tag_network=NA,
            chain_first_tag=first(chain_first_tag),
            chain_cum_fill=0,
            chain_cum_rcpm=0,
            is_leading_chain=first(is_leading_chain),
            chain_allocation=first(chain_allocation),
            chain_length=first(chain_length)
            ) %>%
  ungroup() %>%
  rbind(a6) %>%
  arrange(placement_id,date,chain_codes, place) %>%
  group_by(placement_id, date, chain_codes) %>%
  mutate(lead_tag_network=lead(tag_network)) %>%
  ungroup()

print(2)
p <- list()
q <- list()
bl <- list()
j <-0
imax <- min(30, length(levels(a2$placement_id)))

a2.5 <- a2 %>%  filter(is_leading_chain,
                      date %in% (as.Date("2016-08-19")+0:9),
                      chain_length>2) %>%
  group_by(placement_id) %>%
  filter(n()>=10) %>%
  ungroup() %>%
  droplevels()


print(a2.5 %>% group_by(placement_id) %>% summarise(nrow=n()))
for (i in 1:imax) {
  pid = levels(a2.5$placement_id)[i]
  a3 <- a2 %>% filter(placement_id==pid,
                      is_leading_chain,
                      date %in% (as.Date("2016-08-19")+0:9),
                      chain_length>2)
  if (nrow(a3)<10)
    next

  j <- j+1
  print(sprintf("%d: %s (%d)",i,pid,j))
  max_chain_cum_fill <- max(a3$chain_cum_fill)
  bl[[j]] <- b1 %>% filter(placement_id==pid, date %in% unique(a3$date))
  p[[j]] <- ggplot() +
    geom_path(aes(x=chain_cum_fill,y=chain_cum_rcpm,group=chain_codes, colour=chain_codes), data=a3 %>% filter(chain_allocation<0.1), size=0.25, linetype="71")+
    geom_path(aes(x=chain_cum_fill,y=chain_cum_rcpm,group=chain_codes, colour=chain_codes), data=a3 %>% filter(chain_allocation>=0.1), size=1.25)+
    geom_point(aes(x=chain_cum_fill,y=chain_cum_rcpm, colour=chain_codes, shape=as.factor(tag_network)), data=a3, size=3) +
    geom_point(aes(x=chain_cum_fill,y=chain_cum_rcpm, colour=chain_codes, size=chain_allocation^1.5, shape=as.factor(tag_network)), data=a3%>%filter(chain_length==place)) +
    geom_abline(aes(slope=floor_price,intercept=0),data=bl[[j]],colour="black",linetype="dotdash", size=1.25)+
    geom_text(aes(x=chain_cum_fill,y=chain_cum_rcpm,label=sprintf("%1.2f",chain_cum_rcpm/chain_cum_fill)),data=a3%>%filter(chain_length==place), nudge_x = max_chain_cum_fill/25, check_overlap=T)+
    geom_text(aes(x=max_chain_cum_fill*0.9,y=floor_price*max_chain_cum_fill*0.8,label=sprintf("%1.2f",floor_price)),data=bl[[j]],colour="darkgrey")+
    facet_wrap(~date)+
    scale_x_continuous(labels=scales::percent)+
    labs(x="Fill",y="rCPM",shape="Network")

  #a3 %>% mutate(chain_codes=ifelse(chain_allocation>=0.1, chain_codes,'other')) %>% group_by(chain_codes)
  q[[j]] <- ggplot(data=a3 %>% filter(chain_allocation>=0.01,place==1)) +
    geom_bar(aes(x=factor(1),y=chain_allocation,fill=chain_codes),width=1,position="stack", stat="identity")+
    facet_wrap(~date)+
    scale_y_continuous(labels=scales::percent)
}