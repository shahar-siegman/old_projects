
select s.sitename, av.site domain, av.network, last_status, last_status_date, max(r.date) last_site_performance,
	group_concat(distinct ifnull(l.placement_kind,'waterfall')) placement_types
from (select an.site,
	network,
	substring_index(group_concat(an.status order by timestamp desc),',',1) last_status,
    date(max(timestamp)) last_status_date
    from kmn_available_networks an
    where network in ('pubmatic', 'openx', 'sovrn')
	group by site, network
    having last_status = 1
) av
inner join kmn_layouts l on replace(substring_index(l.tag_url,'//',-1),'www.','') = av.site -- and l.placement_kind is null
inner join kmn_sites s using(siteid)
left join kmn_tag_report r on r.tagid=l.layoutid and r.date >'2017-03-01' and r.impressions > 1000
group by av.site, av.network
having last_site_performance is null or last_site_performance < '2017-04-16'