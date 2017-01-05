-- locating openx missing revenue
select s.sitename, replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
	, sum(served*kmn_floor/1000) min_income
    , sum(income) revenue
    , greatest(sum(served*kmn_floor/1000) - sum(income),0) missing_rev
from kmn_layouts l 
inner join kmn_cpm c force index (idx_timestamp) on (c.tagid=l.layoutid) 
inner join kmn_ads_network an on an.id=c.ads_network_id
inner join kmn_sites s using(siteid)
where c.timestamp >= unix_timestamp('2016-12-10')
and c.date between '2016-12-10' and '2016-12-12'
and an.type='openx'
group by l.siteid, replace(substring_index(l.tag_url,'//',-1),'www.','') 
