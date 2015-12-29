source('session1.R')

session5 <- function(reload=F, full=F, draw=T) {
  if (reload) {
    df <- loadDF2() # in session1
  } else {
    df <- dff # dff is defined in the global environment
  }
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
                      chain)

  m2 <- serveDiscrepancyHistogramByFactor(df,"continent_level")

  p <- list(
    # all the following grpahs show no significant variation - or not enough data to indicate variation - by their respective attribute
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("NA","SA") ),     "continent_level","ua_browser_os"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("NA","SA") ),     "continent_level","browser_old_new"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent=="EU" ),                 "continent_level","ua_browser_os"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent=="EU" ),                 "continent_level","browser_old_new"),
    plotDurationByServedAndTwoAttributes(df %>% filter(!geo_continent %in% c("EU","SA","NA")),"continent_level","ua_browser_os"),
    plotDurationByServedAndTwoAttributes(df %>% filter(geo_continent %in% c("EU","SA","NA")), "continent_level","browser_old_new"),
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

