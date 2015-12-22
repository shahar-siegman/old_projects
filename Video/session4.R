
session4load <- function() {
  df = read.csv("discrepancy_by_placement.csv")
  return(df)
}

session4hist <- function(df) {
  df$ls.15 <- df$lost_imps_percent < 0.15
  ggplot(df) + geom_histogram(aes(x=lost_imps_percent, fill=ls.15),binwidth=0.025) # + xlim(0,1)
}