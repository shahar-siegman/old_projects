library(dplyr)
library(ggplot2)
library(stringr)
# script options
# publir_sample and sltrib use a slightly different data format, may not work
# with updated script
filenames=c(publir_sample="publir/publir_discrep_data.csv",
          sltrib="sltrib/discrepancy_sltrib_all_placements.csv",
          publir_full="publir/publir_discrep_data_full.csv")
groupByChain=T
focusPlacements <- c('ec25be467faf21c9faee17c8d3113d76',
                    'a470a60ee38cdc6b40d847c090c09320',
                    '6b340d3fdea200e70497abe58d364eed',
                    '9bce644af95d117fae294890893930cb',
                    '2dab5ba6896b8d68da10d7fc12d6aae3',
                    '5a2f1809deb79f62de22b7d6a80610d5',
                    '973b527df7e407a42b94fd1b064cae1a',
                    'dc033674dfe005f3238d3e3f3d366ddf',
                    'e97125f642f9b00d73bfb2a221755203')
a <- read.csv(filenames["publir_full"],stringsAsFactors = F)
a <- a %>% rename(served=chain_served)

if (groupByChain)
  a <- a %>% group_by(placement_id,chain,n_tags) %>%
  summarise(stat1=sum(stat1), served=sum(served), house=sum(house))

a <- a %>%  filter(stat1>100) %>%
  mutate(lost_imp=stat1-served-house,
         discrep=lost_imp/stat1,
         fill=served/stat1,
         net_discrep=lost_imp/house) %>%
  filter(discrep > 0)

# extract all networks in chain column by removing the tag number, merging all rows and re-splitting by ":"
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
  networksFormula <- paste0("discrep ~ ",paste(networks, collapse=" + "))
  l <- lm(discrep ~ p + e + j + z + t, a)
  # regressions for effect of network within each placement
  l1 <- lm(discrep ~ placement_id*(p + e + j + z + t), a)

  p1 <- ggplot(a %>% filter(stat1>100)) +
     geom_point(aes(x=n_tags,y=discrep,colour=as.factor(date))) +
     facet_wrap(~placement_id)

  # print(p)
} else {
  # regressions for effect of network regardless of placement
  a <- a %>% filter(placement_id %in% focusPlacements)
  a$n_nets <- 0
  for (i in 1:length(networks))
    a$n_nets = a$n_nets + ifelse(a[[networks[i]]]>0,1,0)
  a <- a %>% mutate(network=substr(chain,1,1)) %>% filter(n_nets==1, n_tags %in% c(1,2,5), placement_id != "bab3a2b6c97481906df2ff0051906382")
  p <- ggplot(a,aes(x=stat1,y=lost_imp,colour=network)) +
    geom_point()+
    geom_smooth(method="lm",formula=y ~ x+0, fullrange=T)+
    facet_grid(n_tags~network, scales="free")+guides(colour=F)
  print(p)
  a$unserved <- a$stat1-a$served
  l <- list()
  for (j in 1:length(networks)) {
    l[[networks[j]]] <- c()
    currvec <- c()
    currR2 <- c()
    for (i in c(1,2,5))
    {

      print(paste0("j=",j,", i=",i, ", networks[[j]]=", networks[j]))
      sub <- a[[networks[j]]]==i
      print(1)
      if (any(sub,na.rm=T))
        m <- lm(lost_imp ~ unserved+0, data=a, subset=sub)
      else {
        m$coefficients=NA
        m$residuals=NA
        m$fitted.values=NA
      }
      print (2)
      currvec <- c(currvec,m$coefficients[1])
      currR2 <- c(currR2, 1-sum(m$residuals^2)/sum((m$residuals+m$fitted.values)^2))
    }
    l[[networks[j]]] <- currvec
    l[[paste0(networks[j],".r2")]] <- currR2
    print(3)
  }
  k_unserved1 <- as.data.frame(l)
}

