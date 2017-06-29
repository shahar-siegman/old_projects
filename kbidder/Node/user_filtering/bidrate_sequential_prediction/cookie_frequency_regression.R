library(ggplot2)

data <- read.csv('../data/cookie_based_session_length_sample1.csv',stringsAsFactors=F)

#placement_id <- '04fe83cd7b0a314d8e08433d2a5a6b60'
#placement_id <- '08a275db4970b76b1b017b24b2244a67'
placement_id <- '28ee3b57ac8ce306c3e8a4ba45f1f563'

regressData <- data[data$placement_id==placement_id &
    data$impressions_per_cookie_50<50 &
    data$impressions_per_cookie_50>0,]

regressData$f_cookies = regressData$n_cookies / sum(regressData$n_cookies)
regressData$l_cookies = log(regressData$n_cookies)
regressData$l_imps = sqrt(regressData$impressions_per_cookie_50)

#res1 <- glm(f_cookies ~ impressions_per_cookie_50, 'binomial', regressData)
res1 <- glm(l_cookies ~ impressions_per_cookie_50, 'Gamma', regressData)
res2 <- glm(l_cookies ~ l_imps, 'gaussian', regressData)

regressData$fitted1 = exp(res1$fitted.values)
regressData$fitted2 = exp(res2$fitted.values)

t <- 0
for (i in 50:150) {
  t <- t + exp(sqrt(i)*res2$coefficients[2] + res2$coefficients[1])
}

regressData <- rbind(regressData,data.frame(
  placement_id = placement_id,
  impressions_per_cookie_50 = 50,
  n_cookies = data[data$placement_id==placement_id & data$impressions_per_cookie_50==50,'n_cookies'],
  f_cookies = 0,
  l_cookies = 0,
  l_imps = 0,
  fitted1 = 0,
  fitted2 = t))

p <- ggplot(regressData)+geom_line(aes(x=impressions_per_cookie_50,y=n_cookies,group=placement_id, colour=placement_id))+
#  geom_line(aes(x=impressions_per_cookie_50, y=fitted1),linetype=2, colour='red')+
  geom_line(aes(x=impressions_per_cookie_50, y=fitted2),linetype=2, colour='blue')