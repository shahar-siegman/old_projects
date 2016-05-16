library(dplyr)
library(ggplot2)
a <- read.csv("hdbd_serve_cum.csv") %>% filter(cpm >0)
b <- read.csv("normal_tag_serve_cum.csv")

fp <- read.csv("all_floor_prices.csv")
fp <- fp %>%
  group_by(placement_id) %>%
  filter(is.na(lag(floor)) | floor !=lag(floor)) %>%
  mutate(is_before=as.Date(date)<='2016-04-10') %>%
  group_by(placement_id, is_before) %>%
  filter(!is_before | as.Date(date)==max(as.Date(date))) %>%
  group_by(placement_id) %>% mutate(fp_density=1/n(), fp_density=cumsum(fp_density)) %>%
  ungroup()

c <- full_join(a,b,by=c("placement_id","cpm"))
c <- full_join(c, fp %>% transmute(placement_id=placement_id, floor=round(floor,1),fp_density=fp_density),by=c(placement_id="placement_id",cpm="floor"))
c <- c %>% group_by(placement_id) %>% mutate(hdbd_imps=hdbd_imps/max(chain_serve_cum, na.rm=T),
                                             hdbd_serve_cum = hdbd_serve_cum/ max(chain_serve_cum, na.rm=T),
                                             chain_serve_cum=chain_serve_cum/max(chain_serve_cum, na.rm=T)) %>%
  ungroup()
p <- ggplot(c) +
  geom_line(aes(x=cpm, y=hdbd_serve_cum),colour="blue", group="placement_id")+
  geom_line(aes(x=cpm, y=hdbd_imps),colour="orchid", group="placement_id")+
  geom_line(aes(x=cpm, y=chain_serve_cum),colour="grey35", group="placement_id")+
  geom_point(aes(x=cpm, y=fp_density),colour="deeppink4", group="placement_id")+
  facet_wrap(~placement_id, scale="free")

print(p)
