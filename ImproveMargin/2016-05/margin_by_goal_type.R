df <- read.csv("margin_sheet.csv")
library(ggplot2)
library(dplyr)
ggplot(df %>% filter(row_type=="placement"))+geom_point(aes(x=current_revshare,y=max_margin,colour=optimization_goal_type))
ggplot(df %>% filter(row_type=="placement"))+
  geom_histogram(aes(x=current_revshare)) +
  facet_wrap(~optimization_goal_type) +
  coord_cartesian(xlim=c(0,0.5))
