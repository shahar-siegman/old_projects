library(dplyr)
library(ggplot2)

a <- read.csv("publir_discrep_data.csv",stringsAsFactors = F)%>% filter(stat1>100) %>% mutate(discrep=lost_imp/stat1)

networks <- c("p","e","j","z","t")

for (i in 1:length(networks)) {
  net <- networks[i]
  a[[net]] <- str_length(a$chain) - str_length(str_replace_all(a$chain,net,""))
}

l <- lm(discrep ~ p + e + j + z + t, a)
l1 <- lm(discrep ~ placement_id*(p + e + j + z + t), a)

# p <- ggplot(a %>% filter(stat1>100)) +
#   geom_point(aes(x=n_tags,y=discrep,colour=as.factor(date))) +
#   facet_wrap(~placement_id)
#
# print(p)
