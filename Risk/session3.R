source('C:/Shahar/Projects/Risk/session1.R')
source('C:/Shahar/Projects/Risk/session2.R')

smartSolver <- function (r1, r2, pc=NULL) {
  # list of variables for easy reading
  vars <- c("S0", "S1", "S2", "S3", "r1", "r2", "rhs")

  nonvars <- NULL
  "%!in%" = Negate("%in%")
  if (pc$W["w1"] ==0) {
    vars <- vars[vars %!in% c("S1","r1")]
    nonvars <- union(nonvars, c("S1"))
  }
  if (pc$W["w2"] ==0) {
    vars <- vars[vars %!in% c("S2","r2")]
    nonvars <- union(nonvars, c("S2"))
  }

  ncol <- length(vars)
  v <- rep(list(numeric(ncol)),7)
  for (i in 1:ncol)
    v[[i]][i] <- 1

  names(v) <- c(vars,nonvars)

  if (is.null(pc))
    pc <- calcProblemCoeffs()

  eqn <- buildEquations(pc, v, r1, r2)

  s3r <- s3Range(pc$E, pc$W, r1, r2)
  s3Min <- max(s3r$mins)
  s3Max <- min(s3r$maxes)
  #print(paste0("s3Min=",s3Min,", s3Max=",s3Max))
  if (s3Min <= s3Max) {
    eqn <- rbind(eqn, v$S3 + (s3Min+s3Max)/2*v$rhs) #eqn <- rbind(eqn, v$S3 - v$S2)
    eqn <- rbind(eqn, v$r1 + r1*v$rhs)
    eqn <- rbind(eqn, v$r2 + r2*v$rhs)
  }
  else {
    W <- as.list(pc$W)
    E <- as.list(pc$E)
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
  names(x) <- vars[vars != "rhs"]
  return(x)
}

iterativeSmartSolver <- function(r1, r2, cf=NULL) {
  i <- 1
  nr1 <- r1
  nr2 <- r2
  x <- smartSolver(nr1, nr2, cf)
  while (any(x < -0.001) && i<10) {
    print(paste0("i=",i,", x=", paste0(x,collapse = ", ")))
    nr1 <- nr1 /2
    nr2 <- nr2 /2
    x <- smartSolver(nr1, nr2, cf)
    i <- i+1
  }
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
