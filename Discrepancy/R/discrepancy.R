library("RMySQL")
# get the placement data
plcmnt_chain_date <- read.csv("data_300_placements.txt")
plcmnt_chain_date$Date <- as.Date(plcmnt_chain_date$Date)

# get the website per placement
plcmnt_id_vec=unique(plcmnt_chain_date$placementId)

con <- dbConnect(MySQL(), user="komoona", password="nvlvnjfwe",
                 dbname="komoona_db", host="komoonadevdb.cesnzoem9yag.us-east-1.rds.amazonaws.com")
on.exit(dbDisconnect(con))
f <- function(y) {
  dbGetQuery(con,paste("SELECT layoutid, tag_url FROM kmn_layouts WHERE layoutid= '",y,"'",sep="")) # e.g. select layoutid, tag_url from kmn_layouts where layoutid="0044a86227b3126f9d03c3615712d6b5";
}
data <- lapply(plcmnt_id_vec, f)

# build data frame from list
data_df=data[[1]]
for (i in seq(2,length(data))) {
  data_df <- rbind(data_df,data[[i]])
}

cbind(aggregate(plcmnt_chain_date$Impressions,plcmnt_chain_date,sum),
# next steps:
# 1. aggregate placement_chain_date by placement_id using aggregate
# 2. fetch the tag_url corresponding to each placement_id and add it as a column to the df.


