library(dplyr)
library(ggplot2)
a= read.csv('./data/tsne_sample1.csv', stringsAsFactors = F)
b <- a %>% filter(reqts>0)
b1 <- b %>%
    mutate(sent_bid = sent_bid *100,
           bidrate = 100*pc_wb/pc_res) %>%
  select(-cost,-pc_wb,-pc_res )
d1 <- dist(b1,"euclidean")
d2 <- d1^2
#t1 <- tsne(d1,k=2, perplexity = 5)
t2 <- tsne(d1,k=2, perplexity = 5, max_iter = 500)
y1 <- data.frame(x=t2[,1],y=t2[,2],win = as.factor(b$cost>0))
p1 <- ggplot(y1)+geom_point(aes(x=x,y=y,colour=win))