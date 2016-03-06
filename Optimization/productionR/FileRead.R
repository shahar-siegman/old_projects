source('../../libraries.R')
library('stringr')
inputFilePath = 'data'

loadAllInputs <- function() {
  files <- list()
  files$names <- list.files(path = inputFilePath, pattern="df_data_[A-Za-z]+_[0-9]+.csv")
  files$networks <- str_extract(files$names, "[A-Z][A-Za-z]+")
  files$ordinals <- str_extract(files$names, "[0-9]+")
  return(loadFiles(files))
}

loadAllFillTables <- function ()
{
  files <-list()
  files$names <- list.files(path = inputFilePath, pattern="Fill_[A-Za-z]+_[0-9]\\.csv")
  files$networks <- str_extract(substr(files$names,6,100), "[A-Z][A-Za-z]+")
  files$ordinals <- str_extract(substr(files$names,6,100), "[0-9]+")
  return(loadFiles(files))
}

loadFiles <- function(files)
{
  networks <- networkDict()
  nfiles <- length(files$names)
  df <- data.frame()
  for (i in 1:nfiles)
  {
    fname <- file.path(inputFilePath,files$names[i])
    df1 <- read.csv(fname)
    currentNetwork <- networks[files$networks[i]]
    df1$network <- currentNetwork
    if (!is.null(files$ordinal))
      df1$ordinal <- files$ordinals[i]
    df <- rbind(df,df1)
  }
  return(df)
}


networkDict <- function () {
  return (c("Aol"="o","Index"="j","OpenX"="e","Pubmatic"="p"))
}
