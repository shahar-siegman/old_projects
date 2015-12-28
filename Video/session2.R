source('session1.R')
# loadHDITable and addContinentHdiLevelColumn are for the country-tier attribute
loadHDITable <- function() {
  country.hdi <- read.csv("country_hdi.csv")
  country.hdi <- country.hdi %>% mutate(hdi_level=as.factor(ifelse(hdi_value>=0.86,"I",ifelse(hdi_value>=0.705,"II","III"))))
  return(country.hdi)
}

addAttribute_ContinentAndHdiLevel <- function(df, country.hdi) {
  country.hdi$code = toupper(country.hdi$code)
  df <- left_join(df,country.hdi, by=c(geo_country = "code"))
  df <- df %>% mutate(continent_level = as.factor(paste(geo_continent,hdi_level)))
  return(df)
}

session2Plot <- function(df, country.hdi) {
  df <- addAttribute_Events(df)
  df <- addContinentHdiLevelColumn(df, country.hdi)
  m <- serveDiscrepancyHistogramByFactor(df, "continent_level")
  plotServeDiscrepancyHistogram(m,"continent_level")
}



responseTree <- function(df) {
  # not much insight gained here
  df <- addAttribute_Events(df)
  fit <- rpart(final ~ resp_vast + vpaidl + resp1, method="class", data=df, control=list(cp=0.0001))
  plot(fit, uniform=TRUE,  main="Classification Tree ")
  text(fit, use.n=TRUE, all=TRUE, cex=.8, minlength =3)
}

