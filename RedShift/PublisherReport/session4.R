source('../../libraries.R')

loadRsByTagData <- function()
{
  read.csv('redshift_list2_served_by_date_tag.csv', stringsAsFactors = F)
}

getListTagData2 <- function()
{
  read.csv('list2_placements_tag_performance2.csv', stringsAsFactors = F)
}

matchTagData <- function()
{
  rsData <- loadRsByTagData()
  sqlData <- getListTagData2() %>% preprocess2(min_served_count=0)

  joinedData <- inner_join(rsData,sqlData,by=c(placement_id="placement_id",
                                               date="date_joined",
                                               served_tag="tag_name"))

  return(joinedData)
}

