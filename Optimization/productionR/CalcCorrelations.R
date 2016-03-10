source('../../libraries.R')

runCalcCorrel <- function (order=1, inputPath= 'data') {
  inputs <- loadAllInputs(inputPath)
  integrateDate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    mutate(Fill = served/ impressions) %>% ungroup()
  tabulatedModels <- loadAllFillTables(inputPath)

  return(calcCorrel(integrateDate,tabulatedModels, order))
}


calcCorrel <- function (inputs, tabulatedModels, order) {
  joinedFills <- getFillsForAllPreChains(inputs,order)
  joinedFills <- getModelOrdinalZeroFillForCurrentTag(joinedFills,tabulatedModels)

  scoreDF <- calcOrderCoeffs(joinedFills, order)

  best <-  optim(c(0,0),fn=score, gr=NULL, scoreDF)

  return(best)
}

calcOrderCoeffs <- function(chainDF, order)
{
  if (order==1)
    return (calcOrder1Coeffs(chainDF))
  else
    return (calcOrder2Coeffs(chainDF))
}

calcOrder1Coeffs <- function(chainDF)
{
  sigXsigY <- function(x,y) sqrt(x*y*(1-x)*(1-y))

  passrate1 <- 1-chainDF$Fill.0
  passrate2 <- 1-chainDF$Fill.1
  passrateBase <- 1-chainDF$Fill.Model
  net1 <- substr(chainDF$chain.0,1,1)
  net2 <- chainDF$chain.1 %>% word(2,2,":") %>% substr(1,1)

  corr12Type <- ifelse(net1==net2,"s","d")
  one <- passrateBase - passrate2

  corr12coeff <- sigXsigY(passrate1,passrateBase) / passrate1
  s=ifelse(corr12Type=="s",corr12coeff,0)
  d=ifelse(corr12Type=="d",corr12coeff,0)


  result <- data.frame("one"=one, "s"=s,"d"=d)
  return(result)
}

calcOrder2Coeffs <- function(chainDF)
{
  passrate1 <- 1-chainDF$Fill.0
  passrate2 <- 1-chainDF$Fill.1
  passrate3 <- 1-chainDF$Fill.2
  passrateBase <- 1-chainDF$Fill.Model
  net1 <- substr(chainDF$chain.0,1,1)
  net2 <- chainDF$chain.1 %>% word(2,2,":") %>% substr(1,1)
  net3 <- chainDF$chain.2 %>% word(3,3,":") %>% substr(1,1)
  corr13Type <- ifelse(net1==net3,"s","d")
  corr23Type <- ifelse(net2==net3,"s","d")

  sigXsigY <- function(x,y) sqrt(x*y*(1-x)*(1-y))

  one <- passrateBase - passrate3
  corr13coeff <- sigXsigY(passrate1,passrateBase) / passrate1
  corr23coeff <- sigXsigY(passrate2,passrate3) / (passrate1*passrate2)

  s=ifelse(corr13Type=="s",corr13coeff,0) + ifelse(corr23Type=="s",corr23coeff,0)
  d=ifelse(corr13Type=="d",corr13coeff,0) + ifelse(corr23Type=="d",corr23coeff,0)

  result <- data.frame("one"=one, "s"=s,"d"=d)

  return(result)
}

score <- function(correls,scoreDF)
{
  correl_s = correls[1]
  correl_d = correls[2]
  scoreDF <- scoreDF %>%
    mutate(r=one + s * correl_s + d * correl_d,
           r2= r^2)
  res=sum(scoreDF$r2)
  return(res)
}

optimLoop <- function(orderTagsObjectiveDF)
{
  par=c(0,0)
  tol= 1e-5
  u=T;
  while(u)
  {
    oldPar = par
    par1 <- optim(par[1], fn=score_s, gr=NULL, method="Brent", lower=-2, upper=2, par[2], orderTagsObjectiveDF)
    par2 <- optim(par[2], fn=score_d, gr=NULL, method="Brent", lower=-2, upper=2, par[1], orderTagsObjectiveDF)
    par=c(par1$par, par2$par)
    euclidDist <- sqrt(sum((oldPar-par)^2))
    print (par)
    u <- euclidDist > tol
    # optim(c(0,0),fn=score, gr=NULL, orderTagsObjectiveDF)
  }
  return(par)
}


