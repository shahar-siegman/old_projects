select s.sitename
    , replace(substring_index(l.tag_url,'//',-1),'www.','') url
	, l.name
	, l.layoutid
    , hbp.header_bidding_id
    , sum(r.impressions) imps
    , sum(r.served) wins
    , max(r.date) last_performance_date
    , hbl.estimated_timeout
    , hbl.suggested_bidtime
from kmn_layouts l
inner join kmn_sites s using(siteid)
inner join kmn_tag_report r on r.tagid=l.layoutid
inner join kmn_header_bidding_placement hbp on hbp.placement_id=l.layoutid
left join kmn_header_bidding_latency hbl on (hbl.header_bidding_id=hbp.header_bidding_id)
where l.placement_kind='kbidder'
and r.date>='2016-10-01'
group by l.layoutid
having imps>5000