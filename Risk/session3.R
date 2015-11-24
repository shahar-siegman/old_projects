source('C:/Shahar/Projects/Risk/session1.R')
source('C:/Shahar/Projects/Risk/session2.R')

smartSolver <- function (r1, r2) {
  # list of variables for easy reading
  vars <- list(S0=1, S1=2, S2=3, S3=4, r1=5, r2=6, rhs=7)
  ncol <- max(unlist(vars))
  v <- lapply(vars, function(v,n) {a <- numeric(n);  a[v] <- 1;  return(a)}, ncol)
  a <- calcProblemCoeffs()

  eqn <- buildEquations(a, v, r1, r2)

  s3r <- s3Range(a$E, a$W, r1, r2)
  s3Min <- max(s3r$mins)
  s3Max <- min(s3r$maxes)
  print(paste0("s3Min=",s3Min,", s3Max=",s3Max))
  if (s3Min <= s3Max) {
    eqn <- rbind(eqn, v$S3 + (s3Min+s3Max)/2*v$rhs) #eqn <- rbind(eqn, v$S3 - v$S2)
    eqn <- rbind(eqn, v$r1 + r1*v$rhs)
    eqn <- rbind(eqn, v$r2 + r2*v$rhs)
  }
  else {
    W <- as.list(a$W)
    E <- as.list(a$E)
    s3min.r1 = (E$e1/W$w1)/(E$e1*W$w13/W$w1 + E$e2*W$w23/W$w2 -  E$e3)
    s3min.r2 = (E$e2/W$w2)/(E$e1*W$w13/W$w1 + E$e2*W$w23/W$w2 -  E$e3)
    s3max.r1 = 1/W$w13
    s3max.r2 = 1/W$w23

    # calcuate how much r1 should change
    delta.r1=(s3Min - s3r$maxes["r1"])/(s3max.r1 - s3min.r1)
    delta.r2=(s3Min - s3r$maxes["r2"])/(s3max.r2 - s3min.r2)


    if(abs(delta.r1/r1) < abs(delta.r2/r2)) {
      # change r1
      print("setting s1=0")
      eqn <- rbind(eqn, v$r1 + v$rhs * (r1+delta.r1))
      eqn <- rbind(eqn, v$r2 + v$rhs * r2)
      eqn <- rbind(eqn, v$S1 )
    } else {
      print("setting s2=0")
      eqn <- rbind(eqn, v$r1+v$rhs*r1)
      eqn <- rbind(eqn, v$r2+v$rhs*(r2+delta.r2))
      eqn <- rbind(eqn, v$S2)
    }
  }
  x <- solve(eqn[,1:(ncol-1)],eqn[,ncol])
  return(x)
}

buildEquations <- function(a, v, r1, r2) {
  W <- as.list(a$W)
  E <- as.list(a$E)
  mat=c();
  mat <- rbind(mat, v$S1*W$w1 + v$S3*W$w13 - 1*v$r1 + 0*v$rhs)  # s1*w1 + s3*w13=R1
  mat <- rbind(mat, v$S2*W$w2 + v$S3*W$w23 - 1*v$r2 + 0*v$rhs)
  mat <- rbind(mat, v$S0*E$e0 + v$S1*E$e1 + v$S2*E$e2 + v$S3*E$e3 +1*v$rhs)
  return(mat)
}


