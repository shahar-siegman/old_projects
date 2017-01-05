library(dplyr)
library(zoo)
library(ggplot2)
library(reshape2)
library(stringr)

r2 <- function(lmmodel)
	1 - sum(lmmodel$residuals^2) / sum(((lmmodel$fitted.values+lmmodel$residuals) - mean((lmmodel$fitted.values+lmmodel$residuals)))^2)