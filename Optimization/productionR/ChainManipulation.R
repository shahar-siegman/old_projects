source('../../libraries.R')
library('stringr')

extractTagsFromChain <- function(chainCode)
{
  # trim square brackets if present
  chainCode1 <- str_replace_all(chainCode,"[\\[\\]]","")
  myTag <- str_split(chainCode1,":")[[1]]
  return (myTag)
}



removeLastTag <- function(chain)
{
# same chain less the ultimate tag
  nc <- word(chain,1,-2,":")
  return(nc)
}

tagPerformanceGroupBy <- function(df,keys)
{
  groupFields <- unique(c(keys,"network","FloorPrice","pfx"))

  df <- df %>% group_by_(.dots = groupFields) %>%
    summarise(Ecpm=sum(Ecpm*served)/sum(served),
              Fill=sum(served)/sum(served/Fill),
              Rcpm=sum(Rcpm*served/Fill)/sum(served/Fill),
              served=sum(served)
              )
  df <- as.data.frame(df)
  return(df)
}

parseSingleTag <- function(myTag) {
  myNetwork <- substr(myTag,1,1)
  # extract the floor price - the rest of characters
  myFloorPrice <- substr(myTag,2,10)
  return (data.frame(network=myNetwork, FloorPrice = as.numeric(myFloorPrice)))
}

parseChain <- function(chain) {
  df <- chain %>% extractTagsFromChain() %>% adply(.margins=1, .fun=parseSingleTag, .id="ordinal")
  df$chain <- chain
  df$ordinal <- as.character(as.numeric(df$ordinal)-1) # from 1-based to 0-based
  return(df)
}


