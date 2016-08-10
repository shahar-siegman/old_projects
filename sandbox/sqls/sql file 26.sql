select *
from kmn_margin_stress_factor;


select *
from kmn_ads_network
where id='057ef4f14ab068149f1be0bac97dd8e7';


select date
	, type
	, sum(impressions) imps
    , sum(served) served
    , sum(income) revenue
from kmn_cpm
where timestamp between unix_timestamp('2016-05-01') and  unix_timestamp('2016-06-01') 
group by type, date;

select *
from kmn_available_networks
where site='baseballprospectus.com';


select tagid
	, l.name
    , replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
	, sum(impressions) impressions
    , sum(served)/sum(impressions) fill
    , sum(1000*(cost+profit))/sum(served) ecpm
from kmn_tag_report r
inner join kmn_layouts l on (l.layoutid=r.tagid)
where tagid in (select placement_id from kmn_header_bidding_placement where enabled=1)
and r.date between '2016-06-10' and '2016-06-30'
group by tagid

