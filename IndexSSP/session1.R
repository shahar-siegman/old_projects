library(ggplot2)
loadAuctions <- function(inputFile=NA) {
  if(identical(inputFile,NA))
    inputFile <- "C:\\Shahar\\Projects\\IndexSSP\\data.txt"
  # Read in the data
  x <- scan(inputFile, what="", sep="\n")
  # Separate elements by one or more whitepace
  y <- strsplit(x, ",")  # bids (seperated by ;), floorprice, responses
  y <- lapply(y,`[`,1) # take bids, throw rest
  y <- unlist(y)
  y <- strsplit(y,";")  # split to individual bids
  y <- lapply(y,as.numeric)
  auctions <- lapply(y,sort,TRUE)
  firsts <- unlist(lapply(auctions,`[`,1))
  seconds <- unlist(lapply(auctions,`[`,2))
  nAuctions <- sum(length(firsts))
  recordsToRemove <- is.na(firsts) | firsts==0
  firsts <- firsts[!recordsToRemove]
  seconds <- seconds[!recordsToRemove]
  seconds[is.na(seconds)] <- 0
  return(list(firsts,seconds,nAuctions))
}

resultsForRange <- function(auctions, minFloorPrice, maxFloorPrice) {
  # result <- data.frame(auctions=numeric(0),floorPrice=numeric(0),wins=numeric(0))
  floorPrices <- sort(unique(unlist(auctions[1:2])))
  if (length(floorPrices)==0) {
    print ("skipping analysis")
    return(data.frame())
}
  floorPrices <- floorPrices[floorPrices>=minFloorPrice & floorPrices <= maxFloorPrice]
  #minFloorPrice=max(minFloorPrice,0)
  #maxFloorPrice=min(maxFloorPrice,max(auctions[[1]]))
  print (maxFloorPrice)
  if (maxFloorPrice==-Inf)
    return(data.frame())
  #increment=0.02
  #floorPrices = seq(minFloorPrice, maxFloorPrice, by=increment)
  r=length(floorPrices)
  result <- matrix(nrow=r,ncol=2)
  for (i in 1:r) {
    fp <- floorPrices[i]
    result[i,] <- resultByFloorPrice(auctions,fp)
  }
  df=data.frame(auctions=auctions[[3]],floorPrice=floorPrices,wins=result[,1],revenue=result[,2])
  df$fill=df$wins/df$auctions
  df$eCpm=df$revenue/df$wins
  return(df)
}

resultByFloorPrice <- function(auctions,floorPrice) {
  firsts <- auctions[[1]]
  seconds <- auctions[[2]]
  winners <- floorPrice <= firsts
  aboveSeconds <- winners & floorPrice >= seconds
  revenue <- (floorPrice+0.01)*sum(aboveSeconds) + sum(seconds[winners & !aboveSeconds])
  return (c(sum(winners), revenue))
}

# resultAllFloorPrice <-function(auctions) {
#   firsts <- unlist(lapply(auctions,`[`,1))
#   seconds <- unlist(lapply(auctions,`[`,2))
#   firsts[is.na(firsts)] <- 0
#   seconds[is.na(seconds)] <- 0
#
#   floorprices = seq(maxFloorPrice,0,by=-0.02)
#   r=length(floorprices)
#   auctions=length(firsts)
#   wins=numeric(r)
#   revenue=numeric(r)
#
#   #result <- data.frame(auctions=numeric(0),floorPrice=numeric(0),wins=numeric(0), revenue=numeric(0))
#   wins=0
#   for(fp in floorPrices) {
#
#   }
#
# }

loopFiles <- function() {
  inputdir="placement_bids\\"
  outputdir="results\\"
  flist <- list.files(inputdir, pattern="*.csv");
  for (fname in flist) {
    print (fname)
    y <- simulateSingleFile(paste(inputdir,fname,sep=""))
    if (nrow(y)>0)  {
      write.csv(y,file=paste(outputdir,fname,sep=""))
    }
    else
      print ("skipping write csv")
  }
}

loopResults <- function() {
  inputdir="results/"
  outputdir="graphs/"
  flist <- list.files(inputdir, pattern="*.csv");
  for (fname in flist) {
    df <- read.csv(paste(inputdir,fname,sep=""))
    p1 <- ggplot(data=df, aes(y=wins, x=floorPrice))+geom_line()+geom_point()
    p2 <- ggplot(data=df, aes(y=eCpm, x=fill))+geom_line()+geom_point()+scale_y_log10()
    p3 <- ggplot(data=df, aes(y=fill, x=floorPrice))+geom_line()+geom_point()
    p4 <- ggplot(data=df, aes(y=revenue, x=fill))+geom_line()+geom_point()
    fname=paste(outputdir,filename=substr(fname,1,nchar(fname)-4),".png",sep="")
    print(paste("file: ",fname,", rows:",nrow(df)))
    png(fname, width=960, height=960)
    grid.arrange(p1,p2,p3,p4,nrow=2,ncol=2)
    dev.off()
  }
}

simulateSingleFile <- function(fname) {
  auctions <- loadAuctions(fname)
  performanceDF <- resultsForRange(auctions,0.01,50)
  return(performanceDF)
}