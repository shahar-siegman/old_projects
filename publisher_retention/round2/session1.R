source('../../libraries.R')
source('./weekly_retention_metric.R')

if (!exists('a')) {
  a <- read.csv('./retention data raw.csv',stringsAsFactors = F)
  a$week_in_year = lapply(a$week_name, function(str) { return (as.integer(strsplit(str,"/")[2])) })
}
b <- weeklyRetention(a)

