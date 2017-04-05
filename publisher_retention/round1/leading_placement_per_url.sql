select
	s.sitename
	, replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url 
	, date
    , substring_index(group_concat(layoutid order by r.impressions desc),',',1) leading_placement
    , max(r.impressions) leading_impressions
    , substring_index(group_concat(served order by r.impressions desc),',',1) leading_placement_served
    , max(served) max_served
	, substring_index(group_concat(cost+profit order by r.impressions desc),',',1) leading_placement_revenue
from kmn_layouts l
inner join kmn_tag_report r on (r.tagid=l.layoutid)
inner join kmn_sites s using(siteid)
where r.date >='2016-08-01'
group by s.sitename, replace(substring_index(l.tag_url,'//',-1),'www.',''), date
