source('../../../libraries.R')

# a <- read.csv('inner_joined_country_device.csv',stringsAsFactors = F)

# placement with at least one tag zero served when redshift shows served
a1 <- a %>% filter(str_length(chain)>0,
                   !startsWith(chain,trimws(code)))

a2 <- inner_join(a1 %>% filter(served==0, cnt>30) %>% group_by(placement_id) %>% summarise(),
                 a1, by="placement_id") %>%
  arrange(tagid,served_tag,date) %>%
  select(tagid,date,code, impressions,served,chain,served_tag, served_tag_network,cnt)

# a2 <- a2 %>% filter(!startsWith(chain,trimws(code)))

a3 <- a2 %>% group_by(tagid,served_tag_network,code) %>%
  filter(sum(cnt)>50) %>%
  mutate(is_zeroserved_tag=ifelse(sum(served)==0,1,0)) %>%
  group_by(tagid,served_tag_network,is_zeroserved_tag) %>%
  summarise(tags=paste(unique(code),collapse=","),
            n_tags=n_distinct(code),
            cpm_served=sum(served),
            rs_served=sum(cnt),
            chains=paste(unique(chain),collapse=","))


a4 <- a3 %>%
  group_by(tagid,served_tag_network) %>%
  summarise(zeroserved_tags=paste(ifelse(is_zeroserved_tag,tags,""),collapse=""),
            other_tags=paste(ifelse(!is_zeroserved_tag,tags,""),collapse=""),
            chains=paste(ifelse(is_zeroserved_tag,chains,""),collapse=""),
            cpm_served=sum(cpm_served),
            rs_served_zeroserved=sum(ifelse(is_zeroserved_tag,rs_served,0)),
            rs_served_other=sum(ifelse(!is_zeroserved_tag,rs_served,0)),
            ntags_other = sum(ifelse(!is_zeroserved_tag,n_tags,0))) %>%
  filter(str_length(zeroserved_tags)>0,cpm_served>=50*ntags_other)

write.csv(a4,'tags_suspicious_zero_served.csv')

