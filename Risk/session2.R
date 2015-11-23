source('C:/Shahar/Projects/Risk/session1.R')

runSession2 <- function() {
  p <- currentRiskLevels();
  risk1Level <- p[1]*1.2
  risk2Level <- p[2]

  l <- session2(risk1Level, risk2Level)
  #  print (l[[1]]/weights*sum(weights))
  return(l)
}

session2 <- function(r1, r2) {
  y <- t(matrix(weights)) /sum(weights)

  w1 <- (y*isRisk1) %*% matrix(ecpmRisk)
  w2 <- (y*isRisk2) %*% matrix(adxRisk)
  w13 <- (y*isRisk12) %*% matrix(ecpmRisk)
  w23 <- (y*isRisk12) %*% matrix(adxRisk)

  e0 <- sum(y*isRisk0)
  e1 <- sum(y*isRisk1)
  e2 <- sum(y*isRisk2)
  e3 <- sum(y*isRisk12)


  z <- s3Range(c(e0=e0,e1=e1,e2=e2,e3=e3),
                 c(w1=w1,w2=w2,w13=w13,w23=w23),
                 r1,
                 r2)
  return(c(z,y[which.max(isRisk12)]))
}

s3Range <- function(E, W, r1, r2) {
  maxes <- unname(c(r1/W["w13"], r2/W["w23"]))
  denom <- unname(W["w13"]*E["e1"]/W["w1"] + W["w23"]*E["e2"]/W["w2"] - E["e3"])
  num <-  unname(E["e1"]*r1/W["w1"] + E["e2"]*r2/W["w2"] -1)
  mins <- 0
  if (denom<0)
    maxes <- c(maxes, num/denom)
  else
    mins <- c(mins, num/denom)

  return(list(r1=r1, r2=r2, maxes=maxes, mins=mins))
}