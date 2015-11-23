weights <-  c(12  , 12,   73,  742,  2, 2,    2,   2,    2, 12, 12, 2, 2, 2)
ecpmRisk <- c(0.25, 0.25, 0.1, 0.05, 0, 0,    0,   0,    0, 0, 0, 0, 0, 0)
adxRisk <-  c(0,    0.1,  0.6, 0.7,  0, 0.25, 0.4, 0.48, 0, 0, 0, 0, 0, 0)

a <- ecpmRisk > 0
b <- adxRisk > 0
isRisk1 <- a & !b
isRisk2 <- !a & b
isRisk12 <- a & b
isRisk0 <- !a & !b

#adxRisk <-  c(0,    0.0,  0.0, 0.0,  0, 0.25, 0.4, 0.48, 0, 0, 0, 0, 0, 0)
#adxRisk <- c(0, 0.1, 0.6, 0.7, 0, 0.25, 0.4, 0.48, 0, 0, 0, 0, 0, 0)

runSession1 <- function() {
  p <- currentRiskLevels();
  risk1Level <- p[1] #* 0.1
  risk2Level <- p[2] #* 0.15

  l <- session1(risk1Level, risk2Level)
#  print (l[[1]]/weights*sum(weights))
  return(l)
}

currentRiskLevels <- function() {
  currentRisk1 <- t(matrix(weights)) %*% matrix(ecpmRisk)/sum(weights)
  currentRisk2 <- t(matrix(weights)) %*% matrix(adxRisk)/sum(weights)


  return(c(currentRisk1, currentRisk2))
}

session1 <- function (risk1Level, risk2Level, fixedS3=0) {
  m0 <- rowsForRiskGroup(weights, isRisk0)
  m1 <- rowsForRiskGroup(weights, isRisk1)
  m2 <- rowsForRiskGroup(weights, isRisk2)
  m12 <- rowsForRiskGroup(weights, isRisk12)


  if (sum(isRisk12)>0) {
    v <- isRisk12*0
    v[which.max(isRisk12)] <- 1
    riskBindOptions <- list(bindByWeight(weights,which.max(isRisk1),which.max(isRisk12)),
                            bindByWeight(weights,which.max(isRisk2),which.max(isRisk12)),
                            1*isRisk12,
                            1*isRisk0,
                            v
                            )
    riskBindValues <- c(0,0,0,0,fixedS3)
  } else {
    riskBinderOptions <- list(numeric(0))
  }

  #i <- 0
  for(i in 5) {
#    i <- i+1;
    print(i)
    s <- solveRiskProblem(list(m1, m2, m12, m0),
                          list(ecpmRisk, adxRisk),
                          riskBindOptions[[i]],
                          list(risk1Level, risk2Level),
                          riskBindValues[i])
    print (s[[1]]/weights*sum(weights))
  }
  return(s)
}

rowsForRiskGroup <- function(weights,members) {
  rowLength <- length(weights)
  memberInd <- which(members)
  mainMember <- min(memberInd)
  #print(paste0("mainMemeber: ", as.character(mainMember), "; memberInd: ",as.character(paste(memberInd,collapse=","))))
  neq <- length(memberInd) - 1
  m <- matrix(0, nrow=max(neq,0), ncol = rowLength)
  if (neq>0)
    for(i in 2:length(memberInd)) {
      m[i-1,mainMember] <- 1/weights[mainMember]
      m[i-1,memberInd[i]] <- -1/weights[memberInd[i]]
      #    print(i); print(memberInd[i])
    }
  return(m)
}


solveRiskProblem <- function(riskGroups, riskWeights, interGroupBinder, RiskValues, binderValue=0) {
  rowLength <- ncol(riskGroups[[1]])
  ones <- rep(1,rowLength)
  bigM <- rbind(do.call(rbind, riskGroups), interGroupBinder, do.call(rbind, riskWeights), ones)
  #  rbind(m1, m2, m12, m0, , ecpmRisk, adxRisk, ones)
  b <- matrix(0,rowLength,1)
  b[(rowLength-3):rowLength] <- c(binderValue, unlist(RiskValues), 1)

  x=solve(bigM,b)
  return(list(x,bigM,b))

}

bindByWeight <- function(weights, ind1, ind2) {
  a <- rep(0,length(weights))
  a[ind1] <- 1/weights[ind1]
  a[ind2] <- -1/weights[ind2]
  return(a)
}
