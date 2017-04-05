select sitename account,
	replace(substring_index(l.tag_url,'//',-1),'www.','') domain, 
    network,
    elt(l.type,'desktop','mobile') device,
	placementid placement_id, 
	l.name placement_name, 
    concat(l.ad_width, 'x',l.ad_height) ad_size,
    sum(a.revenue) network_revenue, 
    sum(r.cost+r.profit) all_networks_revenue, 
    sum(r.impressions) impressions_all_networks,
    sum(a.wins) network_served,
    1000*sum(a.revenue)/sum(r.impressions) network_rcpm,
    1000*sum(a.revenue)/sum(wins) network_ecpm,
	if(replace(substring_index(l.tag_url,'//',-1),'www.','') in ('trueactivist.com','Sporcle.com','trend-chaser.com','cheatsheet.com',
		'lifebuzz.com','math-aids.com','shmoop.com','whatismyipaddress.com') ,'blacklisted','none') blacklisted
from (
	select placementid,
	date,
    network,
	sum(c.total_income) revenue,
	sum(c.impressions) wins
	from kmn_kbidder_cpm c
    where date between '2017-03-20' and '2017-03-26'
    and network = 'defy'
	group by placementid, date, network
) a 
inner join kmn_layouts l on l.layoutid=a.placementid
inner join kmn_tag_report r on l.layoutid = r.tagid and a.date=r.date
inner join kmn_sites s using(siteid)
where r.date between '2017-03-20' and '2017-03-26'
group by account, domain, network, device, placement_id;