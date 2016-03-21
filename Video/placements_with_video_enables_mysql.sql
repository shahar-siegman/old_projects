select b.*, sum(impressions) impressions, sum(served) served, sum(cost+profit) revenue 
from kmn_tag_report r
inner join (
	select siteid, sitename, placement_id, placement_name, group_concat(network order by network) networks 
    from (
		select s.siteid, s.sitename, l.layoutid placement_id, l.name placement_name, a.network, substring_index(group_concat(a.status order by a.timestamp desc),',',1) latest_status
		from kmn_available_networks a 
		inner join kmn_sites s on a.site = s.sitename
		inner join kmn_layouts l on l.siteid = s.siteid
		where network in ('adaptv', 'anyclip', 'anyclipadaptv', 'anyclipoptimatic')
		group by s.siteid, s.sitename, l.layoutid, l.name, a.network
		having latest_status='1'
		) a
	group by siteid, sitename, placement_id, placement_name) b 
	on b.placement_id = r.tagid
    where r.date >='2016-02-01'
    group by placement_id