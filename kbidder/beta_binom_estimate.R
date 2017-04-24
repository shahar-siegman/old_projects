

loglike = function(data) {
  return (function(vec) {
    s <- 0
    n <- nrow(data)
    miu <- vec[1]
    phi <- vec[2]

    for (i in 1:n) {
      arg <- sumOfLogExpression(logMiuOneMinusPhi,0,data[i,]$x-1, miu, phi) +
        sumOfLogExpression(logOneMinusMiu, 0, data[i,]$k - data[i,]$x -1, miu, phi) -
        sumOfLogExpression(logOneMinusPhi, 0, data[i,]$k-1, miu, phi)
      s <- s + data[i,]$count * arg
    }
    print(paste0('miu=',miu,', phi=',phi, ', s=', s))
    return (-s)
  })
}

sumOfLogExpression <- function(expression,start,finish,...) {
  s <- 0;
  if (start <= finish)
    for (r in seq(start,finish) ) s <- s+expression(r,...)
  return (s)
}

logMiuOneMinusPhi <- function(r,miu,phi) {
  return (log(miu*(1-phi)+r*phi))
}

logOneMinusMiu <- function(r,miu,phi) {
  return (log((1-miu)*(1-phi)+r*phi))
}

logOneMinusPhi <- function(r,miu,phi) {
  return (log(1-phi + r*phi))
}

work <- function() {
  rawData <- read.csv('n_k_example.csv',stringsAsFactors = F)
  data <- rawData %>% group_by(k,x) %>% summarise(count=n())

  res <- optim(c(miu=0.1, phi = 0.01), loglike(data), lower=c(1e-6,1e-6), upper=c(1-1e-6,1-1e-6))
  return(res)
}

checkWork <- function(res) {
  miu = res$par["miu"]
  phi = res$par["phi"]
  alpha = miu*(1/phi -1)
  beta = (1/phi-1)*(1-miu)
  print(res)

  print(paste0('alpha=',alpha, ', beta=', beta, ', check: ', miu, '=', alpha/(alpha+beta),
               ',', 1/phi, '=', (alpha+beta+1)))

}