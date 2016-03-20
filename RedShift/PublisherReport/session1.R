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
  df3 <- df3 %>% select(plcmnt_joined, date, tag, cnt, served, impressions) %>%
    rename(placement_id=plcmnt_joined) %>% mutate(code=tag)
  return(df3)
}

summarisePlacementNetwork <- function()
{
  df4 <- getData() %>% preprocess() %>% group_by(placement_id,tag) %>% summarise(cnt=sum(cnt), served=sum(served))
  df4$cnt[is.na(df4$cnt)]=0
  df4$served[is.na(df4$served)]=0
  df4 <- df4 %>% filter(cnt + served >= 500)
  df4 <- df4 %>% mutate(rs_bias = ifelse(cnt<served,cnt/served-1, 1-served/cnt)) %>%
    filter(rs_bias>-0.22, rs_bias < 0.05)

  return(df4)
}

analysis1 <- function()
{
  df1 <- summarisePlacementNetwork()
  ggplot(df1) + geom_density(aes(x=rs_bias, y=..scaled..)) + facet_grid(~tag, scale='free')
}

calcRsBias <- function()
{
  df <- getData() %>% preprocess()
  df1 <- summarisePlacementNetwork() %>% select(placement_id, tag)
  df2 <- inner_join(df, df1, by=c("placement_id","tag"))
  df2 <- df2 %>% mutate(rs_bias = ifelse(cnt<served,cnt/served-1, 1-served/cnt))
  return(df2)
}

analysis2 <- function()
{
  df2 <- calcRsBias()
  ggplot(df2) +  geom_abline(slope=0, intercept=0, colour="gray") +
    geom_path(aes(x=date, y=rs_bias, group=tag, colour=tag)) +
    facet_wrap( ~ placement_id) + coord_cartesian(ylim=c(-0.3,0.3))
}

analysis3 <- function()
{
  df2 <- calcRsBias()
  df2 <- df2 %>% arrange(date) %>% group_by(placement_id,tag) %>% mutate(lag_served=lag(served)) %>% ungroup()
  df2 <- df2 %>% mutate(lag_bias = ifelse(lag_served<served,lag_served/served-1, 1-served/lag_served))
  ggplot(df2) +  geom_abline(slope=0, intercept=0, colour="gray") +
    geom_path(aes(x=date, y=lag_bias, group=tag, colour=tag)) +
    facet_wrap( ~ placement_id) + coord_cartesian(ylim=c(-0.3,0.3))
}

analysis4 <- function(Print=F, w=4)
{
  df2 <- calcRsBias()
  df2 <- df2 %>% arrange(date) %>% group_by(placement_id,tag) %>%  mutate(lag_rs_bias=lag(rs_bias)) %>% ungroup()
  df3 <- df2 %>% arrange(placement_id, code, date)
  df3 <- df3 %>% mutate(bias_pred=rollapply(data = lag_rs_bias, width = w, mean, na.rm=T, partial=T, fill=NA, align="right"))
  df3 <- df3 %>% mutate(pred_served = ifelse(bias_pred>0,(1-bias_pred)*cnt,cnt/(bias_pred+1)))
  df3 <- df3 %>% mutate(pred_bias = ifelse(pred_served < served, pred_served/served-1, 1-served/pred_served))
  p <-  ggplot(df3) +  geom_abline(slope=0, intercept=0, colour="gray") +
    geom_path(aes(x=date, y=pred_bias, group=tag, colour=tag)) +
    facet_wrap( ~ placement_id) #+ coord_cartesian(ylim=c(-0.3,0.3))
  if (Print)
    print(p)
  return(df3)
}