weights <-  c(12  , 12,   73,  742,  2, 2,    2,   2,    2, 12, 12, 2, 2, 2)
ecpmRisk <- c(0.25, 0.25, 0.1, 0.05, 0, 0,    0,   0,    0, 0, 0, 0, 0, 0)
adxRisk <-  c(0,    0.0,  0.7, 0.0,  0, 0.25, 0.4, 0.48, 0, 0, 0, 0, 0, 0)
#adxRisk <- c(0, 0.1, 0.6, 0.7, 0, 0.25, 0.4, 0.48, 0, 0, 0, 0, 0, 0)

runSession1 <- function() {
  currentRisk1 <- t(matrix(weights)) %*% matrix(ecpmRisk)/sum(weights)
  currentRisk2 <- t(matrix(weights)) %*% matrix(adxRisk)/sum(weights)
  jointRiskAttachTo <- 1

  risk1Level <- currentRisk1 * 0.8
  risk2Level <- currentRisk2 * 0.9


  l <- session1(jointRiskAttachTo, risk1Level, risk2Level)
  print (l[[1]]/weights*sum(weights))
  return(l)
}

session1 <- function (jointRiskAttachTo, risk1Level, risk2Level) {
  a <- ecpmRisk > 0
  b <- adxRisk > 0
  isRisk1 <- a & !b
  isRisk2 <- !a & b
  isRisk12 <- a & b
  isRisk0 <- !a & !b
  #print ("m1:")
  m1 <- matForRiskGroup(weights, isRisk1)
  #print ("m2:")
  m2 <- matForRiskGroup(weights, isRisk2)
  #print ("m12:")
  rowLength <- length(weights)
  if (sum(isRisk12)>0)
    m12 <- matForRiskGroup(weights, isRisk12)
  else
    m12 <- matrix(0,0,rowLength)
  #print ("m0:")
  m0 <- matForRiskGroup(weights, isRisk0)


  ones <- matrix(1,nrow=1,ncol=rowLength)
  if (jointRiskAttachTo==1) {
    riskBinder <- c(which.max(isRisk1),which.max(isRisk12))
  }
  else {
    riskBinder <- c(which.max(isRisk2),which.max(isRisk12))
  }

  if (sum(isRisk12)>0) {
    riskBinderRow <- matrix(0,1,rowLength)
    riskBinderRow[1,riskBinder] <- c(1/weights[riskBinder[1]],-1/weights[riskBinder[2]])
  } else {
    riskBinderRow <- matrix(0,0,rowLength)
  }

  bigM <- rbind(m1, m2, m12, m0, riskBinderRow, ecpmRisk, adxRisk, ones)
  b <- matrix(0,rowLength,1)
  b[(rowLength-2):rowLength] <- c(risk1Level, risk2Level, 1)

  x=solve(bigM,b)
  return (list(x,bigM,b))
}

matForRiskGroup <- function(weights,members) {
  rowLength <- length(weights)
  memberInd <- which(members)
  mainMember <- min(memberInd)
  #print(paste0("mainMemeber: ", as.character(mainMember), "; memberInd: ",as.character(paste(memberInd,collapse=","))))
  neq <- length(memberInd) - 1
  m <- matrix(0, nrow=neq, ncol = rowLength)
  if (neq>0)
    for(i in 2:length(memberInd)) {
      m[i-1,mainMember] <- 1/weights[mainMember]
      m[i-1,memberInd[i]] <- -1/weights[memberInd[i]]
      #    print(i); print(memberInd[i])
    }
  return(m)
}