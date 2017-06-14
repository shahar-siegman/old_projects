
SELect siteid,
	sitename, 
    replace(substring_index(l.tag_url,'//',-1),'www.','') domain, 
    nd.network,
    nd.placement_id, 
    day,
    name placement_name,
    total_impressions,
    ifnull(revenue,0)
from kmn_kbidder_placement_network_daily_data nd
inner join kmn_layouts l on l.layoutid =nd.placement_id
inner join kmn_sites using(siteid)
left join (
	select date, 
    tagid placement_id,
    type network,
    sum(income) revenue
    from kmn_cpm 
    where timestamp >= unix_timestamp('2017-04-01')
    group by date, placement_id, network
    ) c on c.date = nd.day and c.placement_id = nd.placement_id and c.network = nd.network
where day >= '2017-04-01'
group by  placement_id, day , nd.network
