select substring_index(l.tag_url,'//',-1) clean_url
	, date
	, sum(r.impressions) impressions
    , sum(r.served) served
    , sum(cost+profit) revenue
    , sum(profit) profit
from kmn_tag_report r
inner join kmn_layouts l on r.tagid=l.layoutid
where r.timestamp > unix_timestamp('2014-01-01') 
group by clean_url, date;