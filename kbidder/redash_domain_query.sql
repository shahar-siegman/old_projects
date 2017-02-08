
select s.sitename account,
 replace(substring_index(l.tag_url,'//',-1),'www.','') domain,
 concat('<a href=http://redash.komoona.com/dashboard/kbidder-domain_1?p_domain=',
	replace(substring_index(l.tag_url,'//',-1),'www.',''),
    '&p_site_id=',
    siteid,
    '> domain link </a>') domain_link,
 -- r.date,
 count(distinct l.layoutid) n_placements,
 sum(r.impressions)/7 daily_impressions,
 sum(r.served)/7 daily_served,
 sum(r.cost)/7 daily_cost,
 concat(round(100*(1-sum(r.cost)/sum(r.cost+r.profit))),'%') komoona_margin
from kmn_tag_report r
inner join kmn_layouts l on l.layoutid=r.tagid
inner join kmn_sites s using(siteid)
inner join kmn_report_final_date non_final on non_final.type='non_final'
where l.placement_kind = 'kbidder'
and siteid in (
	select siteid 
    from kmn_layouts l1
    inner join kmn_tag_report r1 on r1.tagid=l1.layoutid and r1.date>= date_sub(current_date,interval 7 day)
    where l1.placement_kind='kbidder'
    group by siteid
    having count(distinct replace(substring_index(l1.tag_url,'//',-1),'www.','')) > 1 ) 
and r.date between date_sub(non_final.date, interval 6 day) and (non_final.date)
group by account, domain
having daily_cost > 0.05
order by account, domain