source('../../libraries.R')

testCalcCorrel <- function () {
  inputs <- loadAllInputs()
  integrateDate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    mutate(Fill = served/ impressions) %>% ungroup()
  fills <- loadAllFillTables()

  joinedFills <- getFillsForAllPreChains(integrateDate,2)
  joinedFills <- getModelOrdinalZeroFillForCurrentTag(joinedFills,fills)

  scoreDF <- calcOrder2Coeffs(joinedFills)
}

runCalcCorrel <- function ()
{
  inputs <- loadAllInputs()
  integrateDate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    mutate(Fill = served/ impressions) %>% ungroup()
  integrateDate <- integrateDate %>% prefixFills(2)
  fills <- loadAllFillTables()
  return(calcCorrel(integrateDate, fills, 2))
}

calcCorrel <- function (inputs, tabulatedModels, order) {
  orderRows <- inputs[inputs$ordinal==order,]
  tagsWithOrder0Fill <- adply(orderRows, .margins=1, .fun=matchOrderZeroFill, .id= "id", tabulatedModels)
  orderTagsObjectiveDF <- ddply(tagsWithOrder0Fill, .variables="groupingTag", .fun=calcOrderCoeffs, order)
  best <-  optim(c(0,0),fn=score, gr=NULL, orderTagsObjectiveDF)
    #optimLoop(orderTagsObjectiveDF)
  return(best)
}


matchOrderZeroFill <- function(inputRow, tabulatedModels)
{
  # assumes only ordinal-2 rows in input
  currentTag <- paste0(inputRow$network,inputRow$FloorPrice)
  chain <- paste0(inputRow$pfx,":",currentTag)
  chainTags <- parseChain(chain) %>% rename(original_ordinal=ordinal)

  chainTags$ordinal="0"
  chainTagsWithFills <- left_join(chainTags %>%
                                    mutate(network=as.character(network)),
                                  tabulatedModels  %>%
                                    select(ordinal, network, FloorPrice, Fill=value),
                                  by=c("network","FloorPrice","ordinal"))
  chainTagsWithFills$FillSource <- "model"
  currentTagRow <- inputRow %>%
    select(original_ordinal=ordinal,network,FloorPrice, Fill)
  currentTagRow$FillSource <- "actual"
  result <- rbind(chainTagsWithFills %>% select(-ordinal), currentTagRow)
  result$groupingTag <- currentTag
  return(result)
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
  net <- chainDF$network
  fill <- 1 - chainDF$Fill
  corr12Type <- ifelse(net[1]==net[2],"s","d")
  one <- fill[2]-fill[3]
  denom <- fill[1]
  corr12coeff <- sqrt((1-fill[1])*fill[1]*(1-fill[3])*fill[3])/denom

  s=0; d=0; ss=0; sd=0; dd=0
  if (corr12Type=="s")
    s = s + corr12coeff
  else
    d = d + corr12coeff

  result <- data.frame("one"=one, "s"=s,"d"=d)
  return(result)
}

calcOrder2Coeffs <- function(chainDF)
{
  net <- chainDF$network
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

  s=0
  d=0

  if (corr13Type=="s")
    s = s + corr13coeff
  else
    d = d + corr13coeff

  if (corr23Type=="s")
    s = s + corr23coeff
  else
    d = d + corr23coeff


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


