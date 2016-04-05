source('../../libraries.R')

getMysqlTagData5 <- function()
{
  # joined redshift and mysql, aggregated by placement, network, date
  read.csv('mysql_tag_level.csv', stringsAsFactors = F)
}

getRedshiftDataWithFinalState5 <- function()
{
  read.csv('by_served_tag_and_final_state.csv', stringsAsFactors = F)
}


joinData5 <- function()
{
  dfMysql <- preprocessMysql5()
  dfRedShift <- preprocessRedshift5(T)
  dfBoth <- full_join(dfMysql, dfRedShift, by = c('placement_id', 'date', 'served_tag'))
  dfBoth <- calcBias(dfBoth,'cnt','served')
  dfBoth <- dfBoth %>% mutate(network=substr(served_tag,1,1))
}

preprocessRedshift5 <- function(filter_js_err=T)
{
  df <- getRedshiftDataWithFinalState5()
  if (filter_js_err)
    df <- df %>% filter(final_state != 'js-err')
  df <- df %>% filter(!served_tag %in% c('h',''),
                      as.Date(date) >= as.Date('2016-03-09'),
                      as.Date(date) <= as.Date('2016-03-29'))
  df <- df %>% group_by(date,placement_id, served_tag) %>% summarise(cnt=sum(cnt)) %>% ungroup()
  return(df)
}

preprocessMysql5 <- function()
{
  getMysqlTagData5() %>%
    select(placement_id, tag_name, date_joined, impressions, served) %>%
    rename(date=date_joined, served_tag=tag_name) %>%
    filter(as.Date(date) >= as.Date('2016-03-09'),
          as.Date(date) <= as.Date('2016-03-29'))
}

analysis12 <- function()
{
  df <- joinData5()
  df <- df %>%
    group_by(placement_id, date, network) %>%
    summarise(cnt=sum(cnt), served=sum(served)) %>%
    calcBias('cnt','served')
  ggplot(df) +
    geom_line(aes(x=date,y=cnt_bias, group=network, colour=network)) +
    facet_wrap(~placement_id) +
    coord_cartesian(ylim=c(-0.3,0.3))
}

analysis13 <- function()
{
  df <- joinData5()
  df <- df %>%
    group_by(placement_id, date) %>%
    summarise(cnt=sum(cnt), served=sum(served)) %>%
    calcBias('cnt','served')
  ggplot(df) +
    geom_density(aes(x=cnt_bias)) + coord_cartesian(xlim=c(-1,1))
}


