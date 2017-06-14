suppressMessages(library(dplyr))
if (exists('externalArgs')) {
  args <- externalArgs
} else {
  args <- commandArgs(trailingOnly = TRUE)
}
argument1 <- args[1]
argument2 <- args[2]

inputDir <- dirname(argument1)
inputFile <- basename(argument1)
inputFileNoExt <- strsplit(inputFile,'.',fixed=T)[[1]][1]
outputFile <- ifelse(length(argument2)>3,
                     argument2,
                     file.path(inputDir,paste0(inputFileNoExt,'_coeffs.csv')))

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
         interaction_factor = wb * res
  )
networks = levels(a$network)
output = data.frame()

for (k in 1:length(networks)) {
  d <- a %>% filter(network==networks[k]) %>%
    mutate(placement_id = as.factor(placement_id))
  placements = levels(d$placement_id)
  print(paste0('network: ', networks[k], '; placements: ', paste(placements,collapse=',')))
  for (i in 1:length(placements)) {
    current_placement <- levels(d$placement_id)[i]
    #print(paste0("i=",i,"placement: ",current_placement))

    b1 <- d %>% filter(placement_id == current_placement,
                       !is_100percent_fill,
                       has_cookie)
    if (nrow(b1)<10 || nrow(b1 %>% filter(wb>0))<5) {
      print(paste0('b1: placement ', current_placement, ': ', nrow(b1), ' rows; ', nrow(b1 %>% filter(wb>0)), ' nonzero-wb rows'))
      reg1=list(coefficients=c(0,0,0,0,0),residuals=c(0,0))
    } else {
      reg1 = lm(bid_rate ~ bid_rate_so_far + wb + res + interaction_factor, b1)
    }
    #print(paste0('1: ', reg1$coefficients[1]))
    #print(paste0('2: ', reg1$coefficients[2]))
    #print(paste0('3: ', reg1$coefficients[3]))
    #print(paste0('4: ', reg1$coefficients[4]))
    #print(paste0('5: ', reg1$coefficients[5]))

    b2 <- d %>% filter(placement_id == current_placement,
                       is_100percent_fill,
                       has_cookie)
    if (nrow(b2)<10) {
      print(paste0('b2: placement ', current_placement, ': ', nrow(b2), ' rows'))
      reg2 = list(coefficients=c(0,0,0,0,0),residuals=c(0,0))
    } else {
      reg2 = lm(bid_rate ~ res, b2)
    }

    row <- data.frame(network = networks[k],
                      placement_id = current_placement,
                      model1_bid_rate_so_far = reg1$coefficients[2],
                      model1_bids_in_session = reg1$coefficients[3],
                      model1_requests_in_session = reg1$coefficients[4],
                      model1_bids_request = reg1$coefficients[5],
                      model1_intercept = reg1$coefficients[1],
                      model2_requests = reg2$coefficients[2],
                      model2_intercept = reg2$coefficients[1],
                      model1_rms = sqrt(mean(reg1$residuals^2)),
                      model2_rms = sqrt(mean(reg2$residuals^2)),
                      model1_5_0 = reg1$coefficients[1] + reg1$coefficients[4]*5,
                      model1_5_5 = reg1$coefficients[1] +
                        reg1$coefficients[2]+
                        reg1$coefficients[3]*5 +
                        reg1$coefficients[4]*5 +
                        reg1$coefficients[5]*25,
                      model2_5_5 = reg2$coefficients[1] +
                        reg2$coefficients[2]*5)

    output <- rbind(output, row)
    #row.names(output) <- levels(a$placement_id)
  }
}

write.csv(output, outputFile, row.names = F)
