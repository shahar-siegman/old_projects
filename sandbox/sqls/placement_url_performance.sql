select layoutid
	, l.name
    , replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
    , floor_price
    , date
    , r.impressions
    , r.served
    , (r.cost+r.profit) revenue
    , r.cost client_revenue
    
from kmn_layouts l
inner join kmn_sites s using(siteid)
inner join kmn_tag_report r on (r.tagid=l.layoutid)
-- where s.sitename like '%wazimo%'
where s.sitename = 'Publir.com'
and l.name like 'AllenbWest%'
-- and s.sitename not like 'wazimo%'
and date >='2016-01-01';


select *
from kmn_layouts
where layoutid='bf0a1ec74039e7f5dcfb63c45d990e77';