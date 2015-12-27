source('session1.R')

session5 <- function(reload=F, draw=T) {
  df = df3
  if (reload) {
    df <- loadDF2() # in session1
    df <- regularizeEvents(dfd)
  }
  if (!draw)
    return(df)


  df <- regularizeBrowserVersion(df)

}

session5ServeRacePlot <- function(df, columns) {

  p <- ggplot() +
    geom_density(data= df %>% filter(resp4), aes(x=tvadStart), fill="blue") +
    geom_density(data= df %>% filter(resp1 & !resp4 & !resp5 & lastHb>0), aes(x=lastHb),fill="red", alpha=0.25) +
    xlim(0,60000) +
    facet_wrap(as.formula(columns))
  print(p)
}

regularizeBrowserVersion <- function(df) {
  df$ua_browser_ver <- as.numeric(sub("\\..*","",df$ua_browser_ver))
  df <- adply(df, 1, regluarizeBrowserVersion_)
}

range2word <- function(x, cuts, outcome) {
  outcome[findInterval(x,cuts)+1]
}

regularizeBrowserVersion_ <- function(.) {
  ifelse(.$ua_browser=="Chrome", range2word(.$ua_browser_ver,46,c("old","new")),
         ifelse(.$ua_browser=="Firefox", range2word(.$ua_borwser_ver,42, c("old","new")),
                ifelse(.$ua_browser=="Internet Explorer",range2word(.$ua_borwser_ver,10, c("old","new")),
                       ifelse(.$ua_browser=="Opera", range2word(.$ua_borwser_ver,32, c("old","new")),
                              ifelse(.$ua_browser %in% c("Mozilla","MSN Browser"),"old",
                                     ifelse(.$ua_browswer=="Safari",range2word(ua_borwser_ver,9, c("old","new")),
                                            "unknown")
                              )))))
}