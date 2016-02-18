source("../../libraries.R")
myHyperGeo <- function(n, k, N, K) {
  # calculate the numerator of the Hyper Geometric probability distribution
  # p(k | n, N, K) ~ C(K,k) * C(N-K, n-k)
  # this allows looping over K in estimation scenarios
  choose(K,k) * choose(N-K, n-k)
}

myBinomial <- function(n, k, p) {
  choose(n,k) * p^k * (1-p)^(n-k)
}

testHyperGeo <- function(N=20, K=12, n=8) {
  # verify sum over all k's equals Choose(N,n)
  s1 <- 0
  s2 <- 0
  Nn <- choose(N,n)
  for (k in (max(0,n + K - N)): (min(n,K))) {
    h <- myHyperGeo(n, k, N, K) / Nn
    b <- myBinomial(n, k, K/N)
    s1 <- s1 + h
    s2 <- s2 + b
    print(paste0("k: ", k, ", h: ", h, ", b:", b))
  }
  print(paste0("s1=", s1, ", s2=",s2, ", C(", N, ",", n,") = ", choose(N,n)))
}

hyperGeoConfidence <- function(n, k, N, alpha)
{
  #assert(k <= n && n <= N)
  K_min <- k
  K_max <- N
  K_span <- K_max-K_min+1
  lh <- numeric(K_span) # likelihood
  K <- numeric(K_span)
  for (i in 1: K_span) {
    K[i] <- i + K_min - 1
    lh[i] <- myHyperGeo(n, k, N, K[i])
  }
  lh <- lh/sum(lh)
  m <- sum(K*lh)
  s <- sqrt(sum(K^2 * lh) - m^2)
  df <- data.frame(x=K, likelihood=lh, gauss=dnorm(K, m, s))
  p <- ggplot(df) + geom_path(aes(x,likelihood),color="blue") + geom_path(aes(x,gauss),color="red")
  print(p)
  print(paste0("n=",n, ", k=", k, ", N=", N, ", m=", m, ", sd=", s))
  return(lh)
}

compareVariance <- function(nTrials, N, n, p) {
  nBlackDraw1 = rbinom(nTrials, N, p)
  nBlackDraw2 = rhyper(nTrials, nBlackDraw1, N-nBlackDraw1, n) / n

  nBlackDirect  = rbinom(nTrials, n, p)/ n
  df = data.frame(nBlackDraw2 = nBlackDraw2, nBlackDirect = nBlackDirect)

  print(ggplot(df) + geom_histogram(aes(x=nBlackDirect), fill="blue", binwidth=1/n) + geom_histogram(aes(x=nBlackDraw2), color="red", fill="black",size=2,alpha=0,binwidth=1/n))

  print(paste0(
    "direct: sd=", sqrt(sum((nBlackDirect- p)^2)/(nTrials-1)), ", indirect sd=", sqrt(sum((nBlackDraw2-p)^2)/(nTrials-1))
  ))
}

