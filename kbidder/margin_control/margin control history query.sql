select s.sitename,
	replace(substring_index(l.tag_url,'//',-1),'www.','') domain,
	placement_id, 
 calculation_date, 
    report_date, 
    r.profit,
    r.cost+profit revenue,
    r.profit/(r.cost+r.profit) tag_report_margin,
    actual_margin,
    goal_id, 
    requested_revshare, 
    report_date_adj_revshare, 
    previous_adj_revshare, 
    new_adj_revshare, 
    last_on_Day
from kmn_kbidder_margin_factors mf
inner join kmn_tag_report r on r.tagid=mf.placement_id and r.date=mf.report_date
inner join kmn_layouts l on l.layoutid = r.tagid
inner join kmn_sites s using(siteid)
where report_date >='2017-01-26'
