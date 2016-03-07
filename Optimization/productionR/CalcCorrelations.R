source('../../libraries.R')

testCalcCorrel <- function () {
  inputs <- loadAllInputs()
  fills <- loadAllFillTables()
  sampleRow <- inputs[inputs$ordinal==2,][1,]
  df <- singleChainToDF(sampleRow, fills)
}

runCalcCorrel <- function ()
{
  inputs <- loadAllInputs()
  integrateDate <- inputs %>% group_by(network,FloorPrice,pfx,ordinal) %>%
    summarise(impressions = sum(served/Fill),served=sum(served)) %>%
    mutate(Fill = served/ impressions) %>% ungroup()
  fills <- loadAllFillTables()
  return(calcCorrel(integrateDate, fills, 2))
}

calcCorrel <- function (inputs, tabulatedModels, order) {
  orderRows <- inputs[inputs$ordinal==order,]
  tagsWithOrder0Fill <- adply(orderRows, .margins=1, .fun=matchOrderZeroFill, .id= "id", tabulatedModels)
  orderTagsObjectiveDF <- ddply(tagsWithOrder0Fill, .variables="groupingTag", .fun=calcOrderCoeffs, order)
  best <- optim(c(0,0),fn=score, gr=NULL, orderTagsObjectiveDF)
  return(best)
}

matchOrderZeroFill <- function(inputRow, tabulatedModels)
{
  # assumes only ordinal-2 rows in input
  currentTag <- paste0(inputRow$network,inputRow$FloorPrice)
  chain <- paste0(inputRow$pfx,":",currentTag)
  chainTags <- parseChain(chain) %>% rename(original_ordinal=ordinal)
  #chainTags <- rbind(chainTags,list(NA,inputRow$network, inputRow$FloorPrice))
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
  one <- fill[1]*(fill[2]-fill[3])
  corr12Coeffs <- sqrt((1-fill[1])*fill[1]*(1-fill[3])*fill[3])
}

calcOrder2Coeffs <- function(chainDF)
{
  net <- chainDF$network
  fill <- 1 - chainDF$Fill
  corr12Type <- ifelse(net[1]==net[2],"s","d")
  corr13Type <- ifelse(net[1]==net[3],"s","d")
  corr23Type <- ifelse(net[2]==net[3],"s","d")

  one <- -fill[1] * fill[2] * fill[4]
  corr12coeff <- (fill[3]-fill[4])*sqrt((1-fill[1])*fill[1]*(1-fill[2])*fill[2])
  corr13coeff <- fill[2]*sqrt((1-fill[1])*fill[1]*(1-fill[3])*fill[3])
  corr23coeff <- fill[1]*sqrt((1-fill[2])*fill[2]*(1-fill[3])*fill[3])
  corr12corr13coeff <- (1-fill[1])*sqrt(fill[2]*(1-fill[2])*fill[3]*(1-fill[3]))

  s=0
  d=0
  ss = 0
  dd = 0
  sd = 0
  if (corr12Type=="s")
    s = s + corr12coeff
  else
    d = d + corr12coeff

  if (corr13Type=="s")
    s = s + corr13coeff
  else
    d = d + corr13coeff

  if (corr23Type=="s")
    s = s + corr23coeff
  else
    d = d + corr23coeff


  if (corr12Type=="s" && corr13Type=="s")
    ss=corr12corr13coeff
  else if (corr12Type=="s" && corr13Type=="d" || corr12Type=="d" && corr13Type=="s")
    sd=corr12corr13coeff
  else if (corr12Type=="d" && corr13Type=="d")
    dd=corr12corr13coeff

  result <- data.frame("one"=one, "s"=s,"d"=d, "s.s" = ss, "s.d"=sd, "d.d"=dd)

  return(result)
}

score <- function(correls,scoreDF)
{
  correl_s = correls[1]
  correl_d = correls[2]
  scoreDF <- scoreDF %>%
    mutate(r=one +
             s * correl_s +
             d * correl_d +
             s.s * correl_s * correl_s +
             s.d * correl_s * correl_d +
             d.d * correl_d * correl_d,
           r2= r^2)
  res=sum(scoreDF$r2)
  return(res)
}
