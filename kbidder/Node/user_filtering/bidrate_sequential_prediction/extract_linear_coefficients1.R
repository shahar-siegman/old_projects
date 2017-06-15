suppressMessages(library(dplyr))
# some consts
ouputFileExtensionString = '_coeffs_w_cookies_bid_value.csv'
#_coeffs_w_cookies_bid_value
withCookie = T

# set 1: bid rate
#targetMetric = 'bid_rate'
#model1Regressors = c('bid_rate_so_far', 'wb',  'res', 'interaction_factor')
#model2Regressors = 'res'

# set 2: bid value
targetMetric = 'bid_value'
model1Regressors = c('res_minus_wb', 'res')
model2Regressors = c('res')


# no hoisting - helper functions need to go at the top
applyRegression <- function (reg,x) {
  intercept <- reg$coefficients[1]
  reg <- reg$coefficients[2:(length(x)+1)]

  return (sum(reg*x)+intercept)
}
# end helper functions

# get arguments from the environment (if running from inside an r session)
if (exists('externalArgs')) {
  args <- externalArgs
} else {
  # or, get variables from the command line
  args <- commandArgs(trailingOnly = TRUE)
}
argument1 <- args[1]
argument2 <- args[2]
argument3 <- args[3]

# parse the input arguments, decide on input and output file names
inputDir <- dirname(argument1)
inputFile <- basename(argument1)
inputFileNoExt <- strsplit(inputFile,'.',fixed=T)[[1]][1]
outputFile <- ifelse(length(argument2)>3,
                     argument2,
                     file.path(inputDir,paste0(inputFileNoExt,ouputFileExtensionString)))

print(paste0('argument1: ', argument1, '; out file: ', outputFile))
print(paste0('directory: ', getwd()))

data <- read.csv(argument1,stringsAsFactors=F)

a <- data %>%
  filter(res<50) %>% # this is critical since the data for 50 is false!
  mutate(bids_in_session_factor = as.factor(wb),
         requests_in_session_factor = as.factor(res),
         network = as.factor(network),
         bid_rate_so_far = wb/res,
         bid_rate = with_bid/ with_response,
         bid_value = total_bid_value/ with_bid,
         has_cookie = as.logical(has_cookie),
         is_100percent_fill = wb==res, # catches (0,0)
         interaction_factor = wb * res,
         res_minus_wb = res-wb
  )
networks = levels(a$network)

url_by_placement <- a %>% select(placement_id, tag_url) %>% unique()
output = data.frame()

for (k in 1:length(networks)) {
  d <- a %>% filter(network==networks[k]) %>%
    mutate(placement_id = as.factor(placement_id))
  placements = levels(d$placement_id)
  print(paste0('network: ', networks[k], '; placements: ', paste(placements,collapse=',')))
  for (i in 1:length(placements)) {
    current_placement <- levels(d$placement_id)[i]

    b1 <- d %>% filter(placement_id == current_placement,
                       !is_100percent_fill,
                       has_cookie==withCookie)
    if (nrow(b1)<10 || nrow(b1 %>% filter(wb>0))<5) {
      print(paste0('b1: placement ', current_placement, ': ', nrow(b1), ' rows; ', nrow(b1 %>% filter(wb>0)), ' nonzero-wb rows'))
      reg1=list(coefficients=c(0,0,0,0,0),residuals=c(0,0))
    } else {
      reg1 = lm(formula(paste0(targetMetric,' ~ ', paste0(model1Regressors,collapse=' + '))), b1)
    }

    if (!is.null(model2Regressors)) {
      b2 <- d %>% filter(placement_id == current_placement,
                         is_100percent_fill,
                         has_cookie == withCookie)
      if (nrow(b2)<10) {
        print(paste0('b2: placement ', current_placement, ': ', nrow(b2), ' rows'))
        reg2 = list(coefficients=c(0,0,0,0,0),residuals=c(0,0))
      } else {
        reg2 = lm(formula(paste0(targetMetric,' ~ ', paste0(model2Regressors,collapse=' + '))), b2)
      }
    }
    row <- data.frame(network = networks[k],
                      placement_id = current_placement,
                      tag_url = url_by_placement %>% filter(placement_id==current_placement) %>% `[[`("tag_url") %>% `[`(1) )
    for (m in 1:length(model1Regressors)) {
      row[paste0("model1_",model1Regressors[m])] = reg1$coefficients[m+1]
    }
    row$model1_intercept = reg1$coefficients[1]
    row$model1_rms = sqrt(mean(reg1$residuals^2))
    row$model1_5_0 = applyRegression(reg1,c(0,0,5))
    row$model1_5_5 = applyRegression(reg1,c(1,5,5,25))
    if (!is.null(model2Regressors)) {
      for (m in 1:length(model2Regressors)) {
        row[paste0("model2_",model2Regressors[m])] = reg2$coefficients[m+1]
      }
      row$model2_intercept = reg2$coefficients[1]
      row$model2_rms = sqrt(mean(reg2$residuals^2))

      row$model2_5_5 = applyRegression(reg2,c(5))
    }
    output <- rbind(output, row)
  }
}

write.csv(output, outputFile, row.names = F)

