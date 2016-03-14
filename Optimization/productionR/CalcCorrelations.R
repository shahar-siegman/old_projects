source('../../libraries.R')
optionDefault <- list(correlation=T,use_s=T, use_d=T, use_fill=F, use_pass=T, integrateDate=T)

runCalcCorrel <- function (order=1, inputPath= 'data', inputOptions=list()) {
  inputs <- loadAllInputs(inputPath)
  tabulatedModels <- loadAllFillTables(inputPath)
  options <- mergeByName(optionDefault, inputOptions)

  groupFields <- c("network","FloorPrice","pfx","ordinal")
  if (!options$integrateDate)
    groupFields <- c(groupFields,"date")
  integrate <- inputs %>% group_by_(.dots=groupFields) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    filter(served > 10 & impressions > 10) %>% mutate(Fill = served/ impressions) %>% ungroup()

  options$order=order
  best <- calcCorrel(integrate,tabulatedModels,options)
  return(best)
}


calcCorrel <- function (inputs, tabulatedModels, options) {
  joinedFills <- getFillsForAllPreChains(inputs,options$order)
  joinedFills <- getModelOrdinalZeroFillForCurrentTag(joinedFills,tabulatedModels)

  scoreDF <- calcOrderCoeffs(joinedFills, options)

  best <- list()
  #best$by.optim <-  optim(c(0,0),fn=score, gr=NULL, scoreDF)

  frmla <- makeFormula(options)
  if (options$use_fill)
    scoreDF$y <- 1-scoreDF$y
  best$by.lm <- lm(frmla$formula, scoreDF)
  scoreDF$fitted <- best$by.lm$fitted.values
  best$scoreDF <- scoreDF
  best$gplot <- ggplot(scoreDF) + geom_point(aes(x=fitted, y=y)) + geom_abline(slope=1,intercept =0) + coord_equal()
  best$r2 <- 1 - sum(best$by.lm$residuals^2) / sum((scoreDF$y - mean(scoreDF$y))^2)
  best$AIC = extractAIC(best$by.lm,0, frmla$k)
  return(best)
}

calcOrderCoeffs <- function(chainDF, options)
{
  if (options$order==1)
    return (calcOrder1Coeffs(chainDF,options))
  else
    return (calcOrder2Coeffs(chainDF,options))
}

calcOrder1Coeffs <- function(chainDF, options)
{
  sigXsigY <- function(x,y) sqrt(x*y*(1-x)*(1-y))

  passrate1 <- 1-chainDF$Fill.0
  passrate2 <- 1-chainDF$Fill.1
  passrateBase <- 1-chainDF$Fill.Model
  net1 <- substr(chainDF$chain.0,1,1)
  net2 <- chainDF$chain.1 %>% word(2,2,":") %>% substr(1,1)

  corr12Type <- ifelse(net1==net2,"s","d")
  one <- passrate2 - passrateBase

  if (options$correlation)
    corr12coeff <- sigXsigY(passrate1,passrateBase) / passrate1
  else
    corr12coeff <- 1 / passrate1

  s=ifelse(corr12Type=="s",corr12coeff,0)
  d=ifelse(corr12Type=="d",corr12coeff,0)

  if (!options$use_d) {
    s= s+d
    d= NA
  }

  result <- data.frame("y"=passrate2, "fill"=1-passrateBase, "base"=passrateBase, "s"=s, "d"=d)
  return(result)
}

calcOrder2Coeffs <- function(chainDF, options)
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
  if (options$correlation) {
    corr13coeff <- sigXsigY(passrate1,passrateBase) / passrate1
    corr23coeff <- sigXsigY(passrate2,passrate3) / passrate2
  }
  else
  {
    corr13coeff <- 1 / passrate1
    corr23coeff <- 1 / passrate2
  }
  s=ifelse(corr13Type=="s",corr13coeff,0) + ifelse(corr23Type=="s",corr23coeff,0)
  d=ifelse(corr13Type=="d",corr13coeff,0) + ifelse(corr23Type=="d",corr23coeff,0)

  if (!options$use_d)
  {
    s=s+d
    d=NA
  }
  result <- data.frame("y"=passrate3, "fill" = 1-passrateBase, "base"=passrateBase, "s"=s, "d"=d)

  return(result)
}

score <- function(correls,scoreDF, options)
{
  correl_s = correls[1]
  correl_d = correls[2]
  scoreDF <- scoreDF %>%
    mutate(r=one + s * correl_s + d * correl_d,
           r2= r^2)
  res=sum(scoreDF$r2)
  return(res)
}

mergeByName <- function(init,input) {
  res <- init
  nm <- intersect(names(input), names(init))
  for (i in 1:length(nm))
    res[[nm[i]]] <- input[[nm[i]]]
  return (res)
}


makeFormula <- function(options)
{
  k=0
  frmla <- "y ~ "
  if (options$use_fill) {
    frmla=paste0(frmla," fill")
    k=k+1
  }
  if (options$use_pass)
  {
    frmla=paste0(frmla," + base")
    k=k+1
  }
  if (options$use_s) {
    frmla = paste0(frmla, " + s ")
    k=k+1
    if (options$use_d) {
      frmla = paste0(frmla, " + d ")
      k=k+1
    }
  }
  frmla = paste0(frmla, " + 0")
  k
  return(list(formula=frmla,k=k))
}