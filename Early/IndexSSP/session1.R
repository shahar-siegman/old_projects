library(ggplot2)
library(gridExtra)

simulateSingleFile <- function(fname) {
  auctions <- loadAuctions(fname)
  performanceDF <- resultsForRange(auctions,0.01,50)
  return(performanceDF)
}

loadAuctions <- function(inputFile=NA) {
  if(identical(inputFile,NA))
    inputFile <- "C:\\Shahar\\Projects\\IndexSSP\\data.txt"
  # Read in the data
  x <- scan(inputFile, what="", sep="\n")
  # Separate elements by one or more whitepace
  z <- strsplit(x, ",")  # fields after split: bids (seperated by ;), floorprice, responses
  trueFloorPrices <- lapply(z,`[`,2)
  y <- lapply(z,`[`,1) # take bids, throw rest
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
  trueFloorPrices <- as.numeric(trueFloorPrices[!recordsToRemove])
  seconds[is.na(seconds)] <- 0
  return(list(firsts,seconds,nAuctions,trueFloorPrices))
}

resultsForRange <- function(auctions, minFloorPrice, maxFloorPrice) {
  floorPrices <- sort(unique(unlist(auctions[1:2])))
  if (length(floorPrices)==0) {
    print ("No bidding information supplied")
    return(data.frame())
  }
  print (maxFloorPrice)
  floorPrices <- floorPrices[floorPrices>=minFloorPrice & floorPrices <= maxFloorPrice]
  if (maxFloorPrice==-Inf) {
    print("No bids in range")
    return(data.frame())
  }
  r <- length(floorPrices)
  result <- matrix(nrow=r,ncol=2,dimnames = list(rep(NA,r),c("wins","revenue")))
  for (i in 1:r) {
    fp <- floorPrices[i]
    result[i,] <- resultByFloorPrice(auctions,fp)
  }

  actualResult <- resultByFloorPrice(auctions,auctions[[4]])
  df <- data.frame(floorPrice=floorPrices,wins=result[,1],revenue=result[,2])
  df <- rbind(df,c(mean(auctions[[4]]),actualResult))
  df$floorPriceType <- "simulated"
  df$floorPriceType[nrow(df)] <- "actual"
  df$auctions <- auctions[[3]]
  df$fill=df$wins / df$auctions
  df$eCpm=df$revenue / df$wins
  return(df)
}

resultByFloorPrice <- function(auctions,floorPrice) {
  firsts <- auctions[[1]]
  seconds <- auctions[[2]]
  winners <- floorPrice <= firsts
  aboveSeconds <- winners & floorPrice >= seconds
  revenue <- sum((floorPrice+0.01)*aboveSeconds) + sum(seconds[winners & !aboveSeconds])
  return (c(sum(winners), revenue))
}


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
    p1 <- ggplot(data=df, aes(y=wins, x=floorPrice, colour=floorPriceType, size=floorPriceType))+
      geom_line()+geom_point()+scale_size_manual(values=c(4,0.5))
    p2 <- ggplot(data=df, aes(y=eCpm, x=fill, colour=floorPriceType, size=floorPriceType))+
      geom_line()+geom_point()+scale_y_log10()+scale_size_manual(values=c(4,0.5))
    p3 <- ggplot(data=df, aes(y=fill, x=floorPrice, colour=floorPriceType, size=floorPriceType))+
      geom_line()+geom_point()+scale_size_manual(values=c(4,0.5))
    p4 <- ggplot(data=df, aes(y=revenue, x=fill, colour=floorPriceType, size=floorPriceType))+
      geom_line()+geom_point()+scale_size_manual(values=c(4,0.5))
    fname=paste(outputdir,filename=substr(fname,1,nchar(fname)-4),".png",sep="")
    print(paste("file: ",fname,", rows:",nrow(df)))
    # output a png file with the four graphs on a 2x2 grid:
    png(fname, width=960, height=960)
    grid.arrange(p1,p2,p3,p4,nrow=2,ncol=2)
    dev.off()
  }
}

