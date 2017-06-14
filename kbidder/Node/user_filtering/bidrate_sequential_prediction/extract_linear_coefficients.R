suppressMessages(library(dplyr))
args <- commandArgs(trailingOnly = TRUE)
argument1 <- args[1]

inputDir <- dirname(argument1)
inputFile <- basename(argument1)
inputFileNoExt <- strsplit(inputFile,'.',fixed=T)[[1]][1]
outputFile <- file.path(inputDir,paste0(inputFileNoExt,'_coeffs.csv'))

print(paste0('argument1: ', argument1, '; out file: ', outputFile))
print(paste0('directory: ', getwd()))

data <- read.csv(argument1,stringsAsFactors=F)

a <- data %>%
  filter(requests_in_session <=8) %>%
  mutate(bids_in_session_factor = as.factor(bids_in_session),
         requests_in_session_factor = as.factor(requests_in_session),
         placement_id = as.factor(placement_id),
         bid_rate_so_far = bids_in_session/requests_in_session,
         bid_rate = bids/ impressions,
         bid_value = revenue/ bids,
         is_100percent_fill = bids_in_session==requests_in_session, # catches (0,0)
         interaction_factor = bids_in_session * requests_in_session
  )

placements = levels(a$placement_id)
output = data.frame()
for (i in 1:length(placements)) {

  current_placement <- levels(a$placement_id)[i]
  #print(paste0("i=",i,"placement: ",current_placement))

  b1 <- a %>% filter(placement_id == current_placement,
                    !is_100percent_fill)
  reg1 = lm(bid_rate ~ bid_rate_so_far + bids_in_session + requests_in_session + interaction_factor, b1)
  #print(paste0('1: ', reg1$coefficients[1]))
  #print(paste0('2: ', reg1$coefficients[2]))
  #print(paste0('3: ', reg1$coefficients[3]))
  #print(paste0('4: ', reg1$coefficients[4]))
  #print(paste0('5: ', reg1$coefficients[5]))

  b2 <- a %>% filter(placement_id == current_placement,
                     is_100percent_fill)
  reg2 = lm(bid_rate ~ requests_in_session, b2)


  row <- data.frame(placement_id = current_placement,
                    model1_bid_rate_so_far = reg1$coefficients[2],
                    model1_bids_in_session = reg1$coefficients[3],
                    model1_requests_in_session = reg1$coefficients[4],
                    model1_bids_request = reg1$coefficients[5],
                    model1_intercept = reg1$coefficients[1],
                    model2_requests = reg2$coefficients[2],
                    model2_intercept = reg2$coefficients[1])
  output <- rbind(output, row)
  #row.names(output) <- levels(a$placement_id)
}


write.csv(output, outputFile, row.names = F)
