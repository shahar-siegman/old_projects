gaussianTimeSeries <- function(x, len, absolute=F) {
  # x is a time series, output how far in sigmas each day is relative to the last
  # len days
  lengthX <- length(x)
  y <- numeric(lengthX)
  y[1:len] <- NA
  ss <- numeric(lengthX)
  ss[1:len] <- NA
  for (i in (len+1):(length(x))) {
    samp <- x[(i-len):(i-1)]
    nextX <- x[i]
    m <- mean(samp)
    s <- sd(samp, na.rm=T)
    y[i] <- (nextX-m)/s
    ss[i] <- s
  }
  if (absolute)
    return (y*ss)
  else
    return(y)
}

session2 <- function(net="e", factor=0, conf=0.9) {
  x <- df2a %>% filter(network==net,same_network_ordinal_factor==factor)
  x <- x$avgfill
  lens <- c(3,4,5,6,7,9,11)
  lengthX <- length(x);
  r <- data.frame(len=numeric(0),num=numeric(0),y=numeric(0))
  q <- data.frame()
  for (i in 1:length(lens)) {
    y <- gaussianTimeSeries(x,lens[i],T)
    r <- rbind(r,data.frame(len=rep(lens[i], lengthX),num=1:lengthX, y=y))
    y <- y[!is.na(y)]
    bias= mean(abs(y))
    lenY = length(y)
    ysd = sqrt(sum((y-0)^2)/(lenY-1))
    t_stat= (lenY-1)*ysd^2
    upper = qchisq(conf, df =lenY-1)
    lower = qchisq(1-conf, df =lenY-1)
    sigma_max = sqrt(t_stat/lower)
    sigma_min = sqrt(t_stat/upper)
    q <- rbind(q,c(lens[i], bias, lenY, t_stat, lower, upper, sigma_min, sigma_max))
  }
  names(r) <- c("len","num","y")
  names(q) <- c("len","pred_err", "dof", "T_stat", "chi_lower", "chi_upper",
                "sigma_min","sigma_max")
  return (list(r=r,q=q))
}