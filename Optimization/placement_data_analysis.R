source('../libraries.R')
file='C:/Shahar/Projects/ImproveMargin/kettle_out.csv'

init <- function() {
df <- read.csv(file)
df$r_date <- as.Date(as.Date("1899-12-30")+df$performance_date_xls)
return(df)
}

topByRevenue <- function(df, nt=20) {
  topByRev <- df %>%
    group_by(tagid) %>% summarise(rev=sum(revenue)) %>%
    top_n(nt)
  dfTopRev <- inner_join(df,topByRev)
  return(dfTopRev)
}

groupByPeriod <- function(df, period.length=7) {
  df$period <- floor(df$performance_date/period.length) + 1
  df <- df %>%
    group_by(sitename,tagid,latest_optimization_goal, period) %>%
    summarise(revenue = sum(revenue),
              profit = sum(profit),
              ecpm = 1000*sum(revenue)/sum(served),
              rcpm = 1000*sum(revenue)/sum(impressions),
              impressions = sum(impressions),
              fill = sum(served)/sum(impressions)) %>%
    ungroup()
  return(df)
}

plotNewCoord <- function(df, colorBy="sitename", pathBy="tagid", sizeBy="period") {
  df <- df %>% mutate(x = ecpm * sqrt(1- fill^2))
  ggplot(df) + geom_path(aes_string(x="x",y="rcpm", color = colorBy, group=pathBy)) +
    geom_point(aes_string(x="x",y="rcpm", color =colorBy, size=sizeBy))
}

plotNewCoord1 <- function(df, colorBy="sitename", pathBy="tagid", sizeBy="period") {
  df <- df %>% filter(period==2)
  ggplot(df) + geom_path(aes_string(y="ecpm",x="asin(fill/100)", color = colorBy, group=pathBy)) +
    geom_point(aes_string(y="ecpm",x="asin(fill)", color =colorBy, size=sizeBy)) +
    coord_polar(start=3*pi/2, direction=-1)
}

plotNewCoord2 <- function(df, colorBy="sitename", pathBy="tagid", sizeBy="period") {
  library(plotrix)
  df <- df %>% filter(period==2)
  radial.plot(df$ecpm, asin(df$fill), rp.type="s", label.pos=asin(seq(0.0,1,0.2)), labels = seq(0.0,1,0.2))
}


markVideoPlacements <- function(df) {
  df$isVideo <- df$tagid %in% c(
    '9ae742991f451fb21c6369f45ac34829',
    'c25fb5bd8b899ca4f1dda884a4c6bb8b',
    'c360f219e5df557764af7aa946fb2bc2',
    'cbfd0f7b2f0c9a88093862f041c72407',
    '9ae742991f451fb21c6369f45ac34829',
    '19849c838672e47f7f6800545e1e9fd6',
    '1d0bd2ec4e7928150392dee2a5d49a38',
    '9040b069f174e749fb4cf5102e14e737',
    '544b57d715dd691cca18802e5dc8d993',
    'e51fbb15ca36fb9146659979a6153f69',
    '094b3589d9abde638cc8704400b65e12',
    'f6694d8cfe48a96cde7404e91315440c',
    'bab3a2b6c97481906df2ff0051906382')
  return(df)
}

analysis1 <- function(df) {
  df <- df %>% groupByPeriod() %>%
    markVideoPlacements()
  df <- rbind(df %>% topByRevenue() %>% select(-rev),df[df$isVideo==T,])
  plotNewCoord2(df, colorBy="isVideo", sizeBy="as.factor(floor(log10(impressions)))")
}
