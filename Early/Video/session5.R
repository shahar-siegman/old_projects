source('session2.R')

loadDF3 <- function () {
  DF <- read.csv(paste0(currdir,'30_12_agg.csv'),strip.white=T,na.strings="--")
  DF <- fixS2sColumnNames(DF)
  return(DF)
}

loadDF4 <- function () {
  DF <- read.csv(paste0(currdir,'21_23-12_agg.csv'),strip.white=T,na.strings="--")
  DF <- fixS2sColumnNames(DF)
  return(DF)
}


fixS2sColumnNames <- function(DF) {
  s2sColumnNames = c("s2sCall","start")
  i <- 1
  while (!s2sColumnNames[i] %in% names(DF))
    i <- i+1
  if (i>1)
    DF$s2sCall <- DF[[s2sColumnNames[i]]]

  return(DF)
}


session5 <- function(reload=F, full=F, draw=T) {
  if (reload) {
    df <- loadDF3() # in session1
  } else {
    df <- dff # dff is defined in the global environment
  }
  if (!exists("country.hdi"))
    country.hdi <<- loadHDITable()

  df <- addAttribute_ContinentAndHdiLevel(df, country.hdi)
  if (!"browser_old_new" %in% names(df) || full)
    df <- addAttribute_BrowserOldNew(df)
  df <- addAttribute_Events(df)
  df <- addAttribute_BrowserMainVer(df)
  na.if.not <- function(predicate, x) ifelse(predicate,x,NA)
  df$tvadStartP <- na.if.not(df$resp4, df$tvadStart)
  df$lastHbP <- na.if.not(df$resp1 & !df$resp4 & !df$resp5 & df$lastHb>0, df$lastHb)
  if (!draw)
    return(df)

  df <- df %>% select(geo_continent,
                      geo_country,
                      continent_level,
                      ua_browser,
                      ua_browser_os,
                      ua_browser_ver,
                      final,
                      resp1, resp2, resp3, resp4, resp5,
                      tvadStartP,
                      lastHbP,
                      tvadStart,
                      lastHb,
                      browser_old_new,
                      chain,
                      placement_id)

  m2 <- serveDiscrepancyHistogramByFactor(df,"continent_level")

  p <- list(
    # all the following grpahs show no significant variation - or not enough data to indicate variation - by their respective attribute
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("NA","SA") ),     "continent_level","ua_browser_os"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("NA","SA") ),     "continent_level","browser_old_new"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent=="EU" ),                 "continent_level","ua_browser_os"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent=="EU" ),                 "continent_level","browser_old_new"),
    plotDurationByServedAndTwoAttributes(df %>% filter(!geo_continent %in% c("EU","SA","NA")),"continent_level","ua_browser_os"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("EU","SA","NA")), "continent_level","browser_old_new"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("EU","SA","NA")), "","placement_id"),
    # this summarises the important attribute - continent_level
    plotServeDiscrepancyHistogram(m2,"continent_level")
  )
  return(p)
}

session5DiscrepancyTradeoffPlot <- function(df) {
  m <- serveDiscrepancyHistogramByFactor(df, "continent_level")
  plotServeDiscrepancyHistogram(m2)
}

session5ServeRacePlot <- function(df, columns) {
  p <- ggplot() +
    geom_density(data= df %>% filter(resp4), aes(x=tvadStart), fill="blue") +
    geom_density(data= df %>% filter(resp1 & !resp4 & !resp5 & lastHb>0), aes(x=lastHb),fill="red", alpha=0.25) +
    xlim(0,60000) +
    facet_wrap(as.formula(columns))
  print(p)
}

addAttribute_BrowserOldNew <- function(df) {
  dff <- addAttribute_BrowserMainVer(df)
  df$browser_old_new <- addAttribute_BrowserOldNew_1(dff$ua_browser, dff$browser_main_ver)
  return(df)
}

addAttribute_BrowserOldNew_1 <- function(ua_browser, browser_main_ver) {
  n=length(browser_main_ver)
  browser_old_new=character(n)
  for (i in 1:n) {
    browser_old_new[i] = addAttribute_BrowserOldNew_2(ua_browser[i],browser_main_ver[i])
  }
  return (browser_old_new)
}

range2word <- function(x, cuts, outcome) {
  outcome[findInterval(x,cuts)+1]
}

addAttribute_BrowserOldNew_2 <- function(ua_browser,ua_browser_ver) {
  browser_old_new <- ifelse(ua_browser=="Chrome", range2word(ua_browser_ver,46,c("old","new")),
         ifelse(ua_browser=="Firefox", range2word(ua_browser_ver,42, c("old","new")),
                ifelse(ua_browser=="Internet Explorer",range2word(ua_browser_ver,10, c("old","new")),
                       ifelse(ua_browser=="Opera", range2word(ua_browser_ver,32, c("old","new")),
                              ifelse(ua_browser %in% c("Mozilla","MSN Browser"),"old",
                                     ifelse(ua_browser=="Safari",range2word(ua_browser_ver,9, c("old","new")),
                                            "unknown")
                              )))))
  return(browser_old_new)
}

addAttribute_BrowserMainVer <- function(df) {
  df$browser_main_ver <- as.numeric(sub("\\..*","",df$ua_browser_ver))
  return(df)
}


plotDurationByServedAndTwoAttributes <- function (df, attribute1, attribute2) {
  # filter if below minimum cases
  df <- df %>% group_by_(attribute1, attribute2) %>% filter(n() > 300) %>% ungroup()
  p <- ggplot(df) + geom_histogram(aes(x=tvadStartP), fill="blue",alpha=0.5) +
    geom_histogram(aes(x=lastHbP),fill="red", alpha=0.24) +
    facet_grid(as.formula(paste(c(attribute1,attribute2),collapse="~")), drop=TRUE, scales = "free") +
    xlim(0,60000)
  return(p)
}

outputByAttribute <- function(df,attribute) {
  df <- df %>%
    group_by_(attribute) %>%
    filter(n() > 300) %>%
    ungroup() %>%
    filter(ifelse(is.na(tvadStartP),T,tvadStartP<60000) & ifelse(is.na(lastHbP), T, lastHbP <60000))

  df[[attribute]] <- as.factor(df[[attribute]])
  lev <- levels(df[[attribute]])
  nlev <- length(lev)
  r <- data.frame()
  for (i in 1:nlev) {
    y <- df[df[[attribute]]==lev[i],]
    y1 <- hist.df(y$tvadStartP, seq(0,60000,2000), "tvadStartP")
    y2 <- hist.df(y$lastHbP, seq(0,60000,2000), "lastHbP")
    y3 <- full_join(y1,y2)
    y3[[attribute]]=lev[i]
    r <- rbind(r,y3)
  }
  return(r)
}
