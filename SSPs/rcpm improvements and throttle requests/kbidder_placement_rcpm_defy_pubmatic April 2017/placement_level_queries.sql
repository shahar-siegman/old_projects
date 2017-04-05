
select sitename account,
	replace(substring_index(l.tag_url,'//',-1),'www.','') domain, 
    network,
    elt(l.type,'desktop','mobile') device,
	placementid placement_id, 
	l.name placement_name, 
    concat(l.ad_width, 'x',l.ad_height) ad_size,
    elt(l.type,'desktop','mobile') placement_device,
    sum(a.revenue) network_revenue, 
    sum(r.cost+r.profit) all_networks_revenue, 
    sum(r.impressions) impressions_all_networks,
    sum(wins) network_served,
    1000*sum(a.revenue)/sum(r.impressions) network_rcpm,
    1000*sum(a.revenue)/sum(wins) network_ecpm,
	if(bs.domain is null,'none','blacklisted') blacklisted
from (
	select placementid,
	date,
    network,
	sum(c.total_income) revenue,
	sum(c.impressions) wins
	from kmn_kbidder_cpm c
    where date between '2017-03-20' and '2017-03-26'
    and network = 'pubmatic'
	group by placementid, date, network
) a 
inner join kmn_layouts l on l.layoutid=a.placementid
inner join kmn_tag_report r on l.layoutid = r.tagid and a.date=r.date
inner join kmn_sites s using(siteid)
left join tmp_shahar_pubmatic_requested_blocking_sites bs on replace(substring_index(l.tag_url,'//',-1),'www.','') =bs.domain and (l.type=1 and bs.desktop OR l.type=2 and bs.mobile)
where r.date between '2017-03-20' and '2017-03-26'
group by account, domain, network, device, placement_id
