source('session1.R')

session5 <- function(reload=F, draw=T) {
  if (reload) {
    df <- loadDF2() # in session1
  } else {
    df <- dff # dff is defined in the global environment
  }
  df <- addAttribute_ContinentAndHdiLevel(df, country.hdi)
  df <- addAttribute_BrowserOldNew(df)
  df <- addAttribute_Events(df)
  df <- addAttribute_BrowserMainVer(df)

  df <- df %>% select(geo_continent,
                      geo_country,
                      continent_level,
                      ua_browser,
                      ua_browser_os,
                      ua_browser_ver,
                      lastHb,
                      final,
                      resp1, resp2, resp3, resp4, resp5,
                      tvadStart,
                      browser_old_new)
  df$tvadStartP <- ifelse(df$resp4, df$tvadStart, NA)
  df$lastHbP <- ifelse(df$resp1 & !df$resp4 & !df$resp5 & df$lastHb>0, df$lastHb, NA)
  df$browser_main_ver <- as.numeric(sub("\\..*","",df$ua_browser_ver))
  if (!draw)
    return(df)

  p <- ggplot(df %>% filter(geo_country=="US" )) + geom_histogram(aes(x=tvadStartP), fill="blue",alpha=0.5) +
    geom_histogram(aes(x=lastHbP),fill="red", alpha=0.24) +
    facet_grid(continent_level~ua_browser_os) +
    xlim(0,60000)

  #   p <- ggplot(df %>% filter(resp1 & (resp4 | !resp5 & lastHb>0))) + geom_density(aes(x=tvadStart), fill="blue",alpha=0.5) +
#     geom_density(aes(x=lastHb),fill="red", alpha=0.24) +
#     xlim(0,60000)

#   p <- ggplot() + geom_density(data= df %>% filter (resp4), aes(x=tvadStart), fill="blue",alpha=0.5) +
#     geom_density(data= df %>% filter(resp1 & !resp4 & !resp5 & lastHb>0), aes(x=lastHb),fill="red", alpha=0.24) +
#     xlim(0,60000)
#
  # + facet_wrap(continent_level~browser_old_new)
  #ua_browser=="Chrome           " &browser_main_ver >36
  print(p)
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
  df$browser_old_new <- addAttribute_BrowserOldNew_(dff$ua_browser, dff$ua_browser_ver)
  return(df)
}
addAttribute_BrowserOldNew_ <- function(ua_browser, ua_browser_ver) {
  ua_browser_ver <- as.numeric(sub("\\..*","",ua_browser_ver))
  n=length(ua_browser_ver)
  browser_old_new=character(n)
  for (i in 1:n) {
    browser_old_new[i] = addAttribute_BrowserOldNew_(sub("\\s+$", "", ua_browser[i]),ua_browser_ver[i])
  }
  return (browser_old_new)
}

range2word <- function(x, cuts, outcome) {
  outcome[findInterval(x,cuts)+1]
}

addAttribute_BrowserOldNew_ <- function(ua_browser,ua_browser_ver) {
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


