suppressMessages(library(plyr))
ouputFileExtensionString = '_coeffs.csv'
print('Hello R!')
if (exists('externalArgs')) {
  args <- externalArgs
} else {
  # or, get variables from the command line
  args <- commandArgs(trailingOnly = TRUE)
}

# args[1]: name of csv file to load
# args[2]: comma-separated list of split (grouping) variables
# args[3]: comma-separated list of target variables
# the variables that don't appear in either are explanatory variables
# an explanatory variable that has NAs where the target variable is not NA
# is dropped from the specific model.
# if there are a few NA's, that's an error
argument1 <- args[1]
argument2 <- args[2]
argument3 <- args[3]

# parse argument1 to synthesize an output file name
inputDir <- dirname(argument1)
inputFile <- basename(argument1)
inputFileNoExt <- strsplit(inputFile,'.',fixed=T)[[1]][1]
outputFile <- ifelse(length(argument2)>3,
                     argument2,
                     file.path(inputDir,paste0(inputFileNoExt,ouputFileExtensionString)))

# log the input
print(paste0('argument1: ', argument1, '; out file: ', outputFile))
print(paste0('directory: ', getwd()))


# load the csv into a dataframe
data <- read.csv(argument1,stringsAsFactors=F)

# parse argument2 and check that exists in the data
splitColumnNames <- strsplit(argument2,',',fixed=T)[[1]]
targetColumnNames <- strsplit(argument3, ',', fixed=T)[[1]]



dataNames <- names(data)
requiredColumnNames <- c(splitColumnNames, targetColumnNames)
missingColumns <- setdiff(requiredColumnNames, dataNames )
if (length(missingColumns) >0 )
  stop(paste0("missing columns in data: ", paste0(missingColumns, collapse = ',')))

rhsColumns <- setdiff(dataNames, c(splitColumnNames, targetColumnNames))

print(paste0('received ' , nrow(data), 'x', ncol(data),', ',
             length(splitColumnNames),' split columns, ', length(targetColumnNames), ' target columns, ',
             length(rhsColumns), ' rhs columns'))

# the linear regression wrapper function
regressionWrap <- function(rData, rhsColumns, lhsColumn) {
  # record number of columns before NA filtering
  chunkLength <- nrow(rData)
  # remove all rows where target column is null
  rData <- rData[!is.na(rData[[lhsColumn]]),]
  # check for NAs in the regression columns
  columnNACount <- colSums(is.na(rData[,rhsColumns]),1)
  nr <- nrow(rData)
  reducedRhsColumns <- rhsColumns
  if (nr > 3) {
    for (i in 1:length(rhsColumns))
      if (columnNACount[i]==nr) {
        # drop this column from regression
        # print(paste0('dropping Rhs Column ', rhsColumns[i]))
        reducedRhsColumns <- setdiff(reducedRhsColumns,rhsColumns[i])
      } else if (columnNACount[i] > 0)
        stop(paste0(columnNACount[i], " NAs found in column ", rhsColumns[i]))

    print(paste0('levels: ', paste0(rData[1, splitColumnNames],collapse=','), ', total rows: ', chunkLength,
                 ' no NAs: ',nrow(rData), ' rhs columns: ', length(reducedRhsColumns)))

    # finally ready to run regression
    myFormula <- paste0(lhsColumn,' ~ ', paste0(reducedRhsColumns,collapse=' + '),' + 0')

    reg <- lm(myFormula, rData)

    # match the coefficients to the original columns
    ret <- rep(0, length(rhsColumns))
    names(ret) <- rhsColumns
    for (i in 1:length(reg$coefficients)) {
      ret[names(reg$coefficients)[i]] <- reg$coefficients[i]
    }
    ret <- c(ret, lhsColumn, mean(rData[[lhsColumn]]), nr, sqrt(mean(reg$residuals^2)))
    names(ret) <- c(rhsColumns, 'target','target_mean','nPoints','rms')


    return (ret)
  } else {
    print(paste0('levels: ', paste0(rData[1, splitColumnNames],collapse=','), ' - cannot run model on ',nr,' points'))
    return (c())
  }
}

output <- data.frame()
# perform the regression on each variable
for (i in 1:length(targetColumnNames)) {
  target <- targetColumnNames[i]
  print(paste0('target: ', target))
  ret <- ddply(data, splitColumnNames, regressionWrap, rhsColumns, target)
  output <- rbind(output,ret)
}
write.csv(output, outputFile, row.names=F)