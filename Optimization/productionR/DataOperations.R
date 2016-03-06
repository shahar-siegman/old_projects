source('../../libraries.R')
library('stringr')

joinPrevTagFill <- function(df, keys, phi_s=1, phi_d=1)
{
  # df needs to be grouped by keys
  df <- tagPerformanceGroupBy(df,keys)
  df$prevTagFill <- NA
  df$prevTagSameNetwork <- NA
  nr <- nrow(df)
  for (i in 1:nr)
  {
    if (df[i,"pfx"]!="[]")
    {
      case <- as.data.frame(df[i,keys])
      names(case) <- keys
      chain <- as.character(df[i,"pfx"])
      prevTagDF <- extractTagFromChain(chain,-1) %>% parseSingleTag()
      prevTagPfx <- removeLastTag(chain)
      prevTagCase <- cbind(case,prevTagDF)
      prevTagCase$pfx= prevTagPfx
      prevTagRow <- retrieve.generic(df, prevTagCase)
      df$prevTagFill[i] <- prevTagRow$Fill[1]
      df$prevTagSameNetwork[i] <- ifelse(prevTagDF$network==df$network[i],1,0)
    }
  }
  return(df)
}


retrieve.generic <- function (df, case) {
  # case is a map attribute_name -> value
  # can be used on any df instead of "filter" as a cleaner programmatic alternative
  # code copy-pasted from ...
  cols <- names(case)
  cond <- df[[cols[1]]]==case[[1]]
  if (length(case)>=2)
    for (i in 2: length(case)) {
      cond <- cond & df[[cols[i]]]==case[[i]]
    }
  rows <- df[cond,]
  return (rows)
}
