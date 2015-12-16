source('session1.R')

loadHDITable <- function() {
  country.hdi <- read.csv("country_hdi.csv")
  country.hdi <- country.hdi %>% mutate(hdi_level=as.factor(ifelse(hdi_value>=0.86,"I",ifelse(hdi_value>=0.705,"II","III"))))
  return(country.hdi)
}

addContinentHdiLevelColumn <- function(df, country.hdi) {
  country.hdi$code = toupper(country.hdi$code)
  df <- left_join(df,country.hdi, by=c(geo_country = "code"))
  df <- df %>% mutate(continent_level = as.factor(paste(geo_continent,hdi_level)))
  return(df)
}

session2Plot <- function(df, country.hdi) {
  df <- regularizeEvents(df)
  df <- addContinentHdiLevelColumn(df, country.hdi)
  m <- serveDiscrepancyHistogramByFactor(df, "continent_level")
  plotServeDiscrepancyHistogram(m,"continent_level")
}


regularizeEvents2 <- function(df) {
  s2s <- !is.na(df$s2sCall)
  df$resp1 <- s2s & df$kvidLoaded>0
  df$resp_vast <- ifelse(df$resp1,
                     ifelse(df$vastResponse > 0, "vast_rsp",
                            ifelse(df$vast_false > 0, "vast_F",
                                   ifelse(df$vastTimeout > 0, "vast_timeout", "vast_none"))),NA)
  df$vpaidl <- ifelse(df$resp1, df$tvpaidloaded > 0, NA)
  df$final <- ifelse(df$resp1,ifelse(df$tvadStart > 0, "serve", ifelse(df$tpb > 0, "passback", "discrep")),NA)
  return(df)
}

responseTree <- function(df) {
  df <- regularizeEvents2(df)
  fit <- rpart(final ~ resp_vast + vpaidl + resp1, method="class", data=df, control=list(cp=0.0001))
  plot(fit, uniform=TRUE,  main="Classification Tree ")
  text(fit, use.n=TRUE, all=TRUE, cex=.8, minlength =3)
}

