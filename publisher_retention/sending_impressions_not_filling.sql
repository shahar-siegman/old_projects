select sitename, replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url, name, tagid, imps, served, networks
from 
( select tagid from kmn_tag_report
where date between '2016-04-01' and '2016-10-01'
and placement_kind is null
group by tagid
having sum(served) > 30000) r1
inner join 
( select tagid, sum(impressions) imps, sum(served) served
from kmn_Tag_report
where date between '2016-11-09' and '2016-11-13'
group by tagid
having sum(impressions) > 10000
and sum(served)<1000) r2 using(tagid)
inner join kmn_layouts l on l.layoutid=r2.tagid
inner join kmn_sites using(siteid)
left join (
	select site domain, group_concat(network order by network) networks
	from (
		select site
			, network
			, substring_index(group_concat(status order by timestamp desc),',',1) last_state
			, substring_index(group_concat(date(timestamp) order by timestamp desc),',',1) last_date
			, group_concat(status order by timestamp desc) state_changes
		from kmn_available_networks
		group by site, network
		having last_state=1
		) a 
	group by domain
    ) enabled_networks 
        on enabled_networks.domain = replace(substring_index(l.tag_url,'//',-1),'www.','')
left join tmp_shahar_blocked_domains bd on bd.domain= replace(substring_index(l.tag_url,'//',-1),'www.','') 
where l.status='approved'
and bd.domain is null
;