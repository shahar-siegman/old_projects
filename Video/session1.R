source('../libraries.R')
library(rpart)
currdir <- 'C:/Shahar/Projects/Video/'

loadDF1 <- function() {
  DF <- read.csv(paste0(currdir,'video_placement_data_redshift.csv'),sep="\t",na.strings="--")
  ggplot(DF)+geom_density(aes(x=ad_start_time-tag_start_time,fill=ua_browser), alpha=0.5) + facet_wrap(~placement_id)
}

loadDF2 <- function () {
  DF <- read.csv(paste0(currdir,'10-12_agg.csv'),strip.white=T,na.strings="--")
}
# df$resp1 & !df$resp4 & !df$resp5 & df$lastHb>0,
addAttribute_Events <- function(df) {
  s2s <- !is.na(df$s2sCall) & df$s2sCall > 0
  df$resp1 <- s2s & df$kvidLoaded>0 # !is.na(df$videoLoaded)
  df$resp2 <- df$resp1 & (df$vastResponse > 0 | df$vast_false > 0 | df$vastTimeout > 0)
  df$resp3 <- df$resp1 & df$tvpaidloaded > 0
  df$resp4 <- df$resp1 & df$tvadStart > 0
  df$resp5 <- df$tpb > 0
  df$resp_vast <- ifelse(df$resp1,
                         ifelse(df$vastResponse > 0, "vast_rsp",
                                ifelse(df$vast_false > 0, "vast_F",
                                       ifelse(df$vastTimeout > 0, "vast_timeout", "vast_none"))),NA)
  df$vpaidl <- ifelse(df$resp1, df$tvpaidloaded > 0, NA)
  df$final <- ifelse(df$resp1,ifelse(df$tvadStart > 0, "serve", ifelse(df$tpb > 0, "passback", "discrep")),NA)
  df <- df %>% mutate(last_response_time =
                        ifelse(resp5, tpb,
                               ifelse(resp4, tvadStart,
                                      ifelse(resp3,vpaidloaded,
                                             ifelse(resp2,max(vastResponse, vast_false, vastTimeout, na.rm=T),
                                                    s2sCall))))) %>%
    mutate(last_response_type =
             ifelse(resp5, "6. passback",
                    ifelse(resp4, "5. adStart",
                           ifelse(resp3,"4. vpaidloaded",
                                  ifelse(resp2,"3. vast",
                                         ifelse(resp1,"2. videoloaded",
                                                ifelse(s2s, "1. s2sCall", NA)))))))


  return(df)
}

analyseDF <- function (DF) {
  DF$v_in_string = regexpr("C|f",DF$chain)
  DF %>% group_by(served_tag_network,!is.na(tvadStart),v_in_string) %>% summarise(cnt=n(),pct=n()/nrow(DF))

    ggplot(DF) +
    geom_density(
    aes(x=tvadStart,
        fill=as.factor(v_in_string),
    alpha=0.5)) +
    xlim(0,1e5)
  return(DF)

}

analyzeTimeDiffs <- function (df, verbose=F) {
  df$diff1 <- df$ts2sResponse - df$s2sCall
  df$diff2 <- df$videoLoaded - df$ts2sResponse
  df$diff3 <- df$tvastResponse - df$videoLoaded
  df$diff4 <- df$tvpaidloaded - df$tvastResponse
  df$diff5 <- df$tvadStart - df$tvpaidloaded
  if (verbose) {
    summary(df$ts2sResponse - df$ts2sCall)
    #    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's
    #  -999.0      1.0      2.0    123.4      4.0 111400.0    26126
    summary(df$videoLoaded - df$ts2sResponse)
    #    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's
    # -107400     259     688    1779    1671  167400   27016
    summary(df$tvastResponse - df$videoLoaded)
    #    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's
    #  -99380     539    1104    1663    2644  120900   48598
    summary(df$tvpaidloaded - df$tvastResponse)
    #   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's
    #  -59000    1096    2410    4216    5000  207400   91845
    summary(df$tvadStart - df$tvpaidloaded)
    #   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's
    #   -2319    8730   14360   17430   24000   90520  137210
  }

  l <- nrow(df)
  df2 <- df %>% mutate(is_served=!is.na(tvadStart)) %>%
    select(is_served,diff1,diff2,diff3,diff4,diff5) %>%
    arrange(diff4) %>% mutate(served=cumsum(is_served==T),
                              unserved=cumsum(is_served==F),
                              rel_served = served/(served+unserved),
                              portion = (seq(1,l)/l))
  p <- ggplot(df2) + geom_path(aes(x=diff4/1000,y=rel_served), color="blue") +
    geom_path(aes(x=diff4/1000,y=portion), color="red") +
    xlim(0,30)
  print(p)
  return(df2)
}

analyzeS2s <- function(df) {
  # explore the missing s2s response. Not a good direction as most missing responses pop up in later events
  df$isresponse <- ifelse(is.na(df$s2sCall),NA,!is.na(df$s2sResponse))
  fit <- rpart(isresponse ~ geo_continent + ua_browser + ua_browser_os, method="class", data=df, control=list(cp=0.001))
  plot(fit, uniform=TRUE,  main="Classification Tree ")
  text(fit, use.n=TRUE, all=TRUE, cex=.8, minlength =3)
}

analyzeServeAndDiscrepancy <- function(df) {
# the basic density in time
  df <- addAttribute_Events(df)
  p <- ggplot() +
    geom_density(data= df %>% filter (resp4), aes(x=tvadStart), fill="blue") +
    geom_density(data= df %>% filter(resp1 & !resp4 & !resp5 & lastHb>0), aes(x=lastHb),fill="red", alpha=0.25) +
    xlim(0,60000)
  print(p)
  return(df)
}

TimeHistogramSingleLevel <- function(dff) {
  # generate the data used for the cumulative density plots
  p <- dff %>% filter(resp4)
  d1 <- hist.df(p$tvadStart, breaks=seq(0,800000,1000), "serve_count")

  p <- dff %>% filter(resp1 & !resp4 & !resp5 & lastHb>0)
  d2 <- hist.df(p$lastHb, breaks=seq(0,800000,1000), "discrep_count")

  d <- inner_join(d1, d2, by="bin")
  return(d)
}

plotServeDiscrepancyHistogram <- function(d,factorColumn,absolute=T) {
  # the cumulative density plot
  # input is not normalized - the "absolute" input determines if normalization should go to 100% or out of stat1's
  d <- d %>% group_by_(factorColumn) %>%
    mutate(serve_cum_percent = cumsum(serve_count),
           discrep_cum_percent = cumsum(discrep_count))
  if(absolute) {
    d <- d %>% mutate(serve_cum_percent = serve_cum_percent/sum(serve_count),
                      discrep_cum_percent = discrep_cum_percent/sum(discrep_count))
  }
  else {
    d <- d %>% mutate(serve_cum_percent = cumsum(serve_count)/level_stat1,
                      discrep_cum_percent = cumsum(discrep_count)/level_stat1)
  }
  p <- ggplot(d) +
    geom_path(aes_string(x="serve_cum_percent",
                         y="discrep_cum_percent",
                         color=factorColumn)) +
    geom_point(aes_string(x="serve_cum_percent",
                         y="discrep_cum_percent",
                         color=factorColumn,
                         shape=factorColumn))
}

serveDiscrepancyHistogramByFactor <- function(df, factorColumn) {
  lev <- levels(df[[factorColumn]])
  m <- data.frame()
  for (i in 1:length(lev)) {
    currentLevel = lev[i]
    levelData <- df[!is.na(df[factorColumn]) & df[factorColumn]==currentLevel,]
    print(paste0("level ", currentLevel, " nrows: ", nrow(levelData)))
    if (nrow(levelData)>1000) {
      d <- TimeHistogramSingleLevel(levelData)
      d[factorColumn] <- currentLevel
      d$level_stat1 <- sum(nchar(as.character(levelData$chain))>1, na.rm=T)  # sum a logical
      m <- rbind(m,d)
    } else {
      print(paste0("skipping level ", currentLevel, " with ", nrow(levelData), " rows, at least 1000 required"))
    }
  }
  return(m)
}


hist.df <- function(x, breaks, count_column_name) {
  h <- hist(x, breaks, plot=F)
  d <- data.frame(h$mids, h$counts)
  names(d) <- c("bin",count_column_name)
  return(d)
}


