library(dplyr)
library(ggplot2)
library(stringr)
# script options
filenames=c(publir="publir/publir_discrep_data.csv",
          sltrib="sltrib/discrepancy_sltrib_all_placements.csv")
groupByChain=T

a <- read.csv(filenames["sltrib"],stringsAsFactors = F)

if (groupByChain)
  a <- a %>% group_by(placement_id,chain,n_tags) %>%
  summarise(stat1=sum(stat1), served=sum(served), house=sum(house), lost_imp=sum(lost_imp))

a <- a %>%  filter(stat1>100) %>% mutate(discrep=lost_imp/stat1, fill=served/stat1, net_discrep=lost_imp/house)

# extract all networks in chain column
networks <- str_replace_all(a$chain,'[0-9]+','') %>%
  paste0(collapse=":") %>% strsplit(":") %>% unlist() %>% unique()
networks <- networks[networks!="h"]


for (i in 1:length(networks)) {
  net <- networks[i]
  a[[net]] <- str_length(a$chain) - str_length(str_replace_all(a$chain,net,""))
}

analysisTypes = c(r="regression",s="single_network_chains_only")
analysisType="s"

if (analysisType=="r")
{
  l <- lm(discrep ~ p + e + j + z + t, a)
  # regressions for effect of network within each placement
  l1 <- lm(discrep ~ placement_id*(p + e + j + z + t), a)

  p1 <- ggplot(a %>% filter(stat1>100)) +
     geom_point(aes(x=n_tags,y=discrep,colour=as.factor(date))) +
     facet_wrap(~placement_id)

  # print(p)
} else {
  # regressions for effect of network regardless of placement
  a$n_nets <- 0
  for (i in 1:length(networks))
    a$n_nets = a$n_nets + ifelse(a[[networks[i]]]>0,1,0)
  a <- a %>% mutate(network=substr(chain,1,1)) %>% filter(n_nets==1)
  p <- ggplot(a,aes(x=stat1,y=lost_imp,colour=network)) +
    geom_point()+
    geom_smooth(method="lm",formula=y ~ x+0, fullrange=T)+
    facet_wrap(~n_tags, scales="free")
  print(p)
}
