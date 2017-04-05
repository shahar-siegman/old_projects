select if(date<='2017-03-07','period1','period2') date_range,replace(substring_index(l.tag_url,'//',-1),'www.','') domain,
	sum(impressions) imps,
    sum(served) served,
    sum(income) revenue,
    1000*sum(income)/sum(impressions) rcpm
from kmn_layouts l
inner join kmn_cpm c on c.tagid=l.layoutid
where c.timestamp between unix_timestamp('2017-03-01') and unix_timestamp('2017-03-11')
and c.type='pubmatic'
group by date_range,domain