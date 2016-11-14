
select r.date
	, replace(substring_index(l.tag_url,'//',-1),'www.','') tag_url
    , r.tagid
    , r.impressions tag
    , c.stat1
    , 1 - c.stat1/r.impressions stat1_disc
    , r.served
    , r.cost+r.profit revenue
from kmn_tag_report r
inner join kmn_layouts l on r.tagid=l.layoutid
inner join 
(select
	date, placement_id, sum(impressions) stat1
    from kmn_chain_report re
    -- where placement_id in ('78b2cd88714813d7c0a7e24e587121d8','2a87a2c6af6c19940c6652154f84fb18','27804daaa547bb42d57ddda303d8e9f0','8d635aaa407fc8010bbed39483563203','4a21b52d03ea836c7b268d29945bf2aa','f387f6db1ef198e1381b92be9c5cc3bd','b41c5a90fbf4d4d7e5e004213e61409a','f28ff435d263c6dab1ba316575a8471c','e0c5a2d64c07b59fc3645029c60d2b2e','95939f2d685e094b9ad2cc680d1c21af')
    where date = '2016-11-01'
    group by date, placement_id
    having stat1>10000) c on c.placement_id=r.tagid and c.date=r.date
where cost+profit > 30
order by stat1_disc desc
