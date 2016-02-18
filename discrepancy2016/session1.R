source("../libraries.R")
loadDF <- function() {
  df <- read.csv("data3dates.csv")
}

preprocess <- function(df) {
  df <- df %>% filter(stat1 > 200, served >5) %>% mutate(discrepancy= (stat1-served-passback)/stat1) %>% filter(discrepancy>=0, discrepancy<=1)
}

analysis1 <- function(df) {
  ggplot(df) + geom_histogram(aes(x=discrepancy, y=..density.., fill=as.factor(date)), binwidth=0.02) + coord_cartesian(xlim=c(-0.1,1))
}

analysis2 <- function(df) {
  df1 <- preprocess(df)
  res <- hist(df1 %>% `[[`("discrepancy"), plot=F, breaks=seq(0,1,0.02))
  res <- data.frame(discrepancy=res$mids, n_placements = res$counts) %>% mutate(percent_of_sample=n_placements/sum(n_placements), cumulative_percent=cumsum(percent_of_sample))
}

analysis3 <- function(df, ntop=5) {
  df %>% preprocess() %>%
    mutate(disc_bin = floor(discrepancy/0.02)*0.02+0.01) %>%
    group_by(disc_bin) %>%
    arrange(-impressions) %>%
    top_n(n = ntop, wt = impressions)
}

saveResult2 <- function(df) {
  write.csv(analysis2(df), "discrepancy_summary.csv")
}

saveResult3 <- function(df, ...) {
  write.csv(analysis3(df, ...), "discrepancy_examples.csv")
}