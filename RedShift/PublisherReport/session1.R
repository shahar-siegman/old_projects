source('../../libraries.R')

getData <- function()
{
  read.csv('kettle_out.csv', stringsAsFactors = F)
}

preprocess <- function(df)
{
  df3 <- df %>% mutate(plcmnt_joined = ifelse(placement_id=="",placement_id_1, placement_id))
  df3 <- df3 %>% mutate(tag=ifelse(code=="",served_tag_network,code))
  df3 <- df3 %>% mutate(date=ifelse(date=="", date_1,date))
  df3 <- df3 %>%  filter(tag %in% c("e","o","p","t","j","x","z") , as.Date(date) <='2016-03-13')
  return(df3)
}

summarisePlacementNetwork <- function(df)
{
  df4 <- df3 %>% preprocess() %>% group_by(placement_id,tag) %>% summarise(cnt=sum(cnt), served=sum(served))
  df4$cnt[is.na(df4$cnt)]=0
  df4$served[is.na(df4$served)]=0
  df4 <- df4 %>% filter(cnt + served >= 500)
  df4 <- df4 %>% mutate(rs_bias = ifelse(cnt<served,cnt/served-1, 1-served/cnt)) %>%
    filter(rs_bias>-0.22, rs_bias < 0.05)

  return(df4)
}

analysis1 <- function(df)
{
  df <- getData()
  df1 <- summarisePlacementNetwork(df)
  ggplot(df1) + geom_density(aes(x=rs_bias, y=..scaled..)) + facet_grid(~tag, scale='free')
}

analysis2 <- function(df)
{
  df <- getData() %>% preprocess()
  df1 <- summarisePlacementNetwork(df) %>% select(placement_id, tag)
  df2 <- inner_join(df, df1, by=c("placement_id","tag"))
  df2 <- df2 %>% mutate(rs_bias = ifelse(cnt<served,cnt/served-1, 1-served/cnt))
  ggplot(df2) + geom_path(aes(x=date, y=rs_bias, group=tag, colour=tag)) +
    facet_wrap( ~ plcmnt_joined) + coord_cartesian(ylim=c(-0.3,0.3))
}