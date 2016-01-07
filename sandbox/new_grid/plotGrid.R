source('C:/Shahar/Projects/libraries.R')

plotGridMain <- function() {
  ecpms <- seq(0,5)
  fills <- seq(0, 1, 0.05)
  f <- performanceGrid(ecpms,fills)
  f <- calculateXY(f)
  return(plotGrid(f))
}

performanceGrid <- function(ecpms, fills) {
  l1 <- length(ecpms)
  l2 <- length(fills)
  major <- F
  y <- data.frame(ecpm=0, fill=0, major=T)
  for(i in 1:l1) {
    major <- F
    for(j in 1:l2) {
      major <- !major
      y <- rbind(y, c(ecpms[i], fills[j], major))
    }
  }
  return(y)
}

calculateXY <- function(d) {
  d <- d %>% mutate(x=ecpm*sqrt(1-fill^2), y=ecpm*fill)
}

plotGrid <- function(y) {
  ggplot() +
    geom_path(data= y %>% filter(major==T), aes(x=x, y=y, group=as.factor(ecpm)),color="grey") +
    geom_point(data= y %>% filter(major==T), aes(x=x, y=y),color="grey") +
    geom_path(data= y %>% filter(major==T), aes(x=x, y=y, group=as.factor(fill)),color="grey") +
    geom_path(data= y %>% filter(major==F), aes(x=x, y=y, group=as.factor(fill)),color="grey", linetype="dashed")
}

