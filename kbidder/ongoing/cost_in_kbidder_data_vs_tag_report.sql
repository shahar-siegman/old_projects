select placement_id, sitename account, clean_url domain, date_, cost_a, ifnull(cost_b,0) cost_b
from (
	select sitename, replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url, placement_id, date(hour) date_, sum(total_win_value) cost_a
	from kmn_kbidder_data d
    inner join kmn_layouts l on l.layoutid = d.placement_id
    inner join kmn_sites using(siteid)
	where hour >='2016-12-01'
	group by placement_id,date_) a
left join 
(
	select layoutid, date, cost cost_b
	from kmn_tag_report r
	inner join kmn_layouts l on l.layoutid =r.tagid
	where l.placement_kind = 'kbidder'
	and date >='2016-12-01') b on a.placement_id=b.layoutid and a.date_=b.date;
    


