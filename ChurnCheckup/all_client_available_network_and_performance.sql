explain 
select sitename
	, r.date
    , replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
    , count(1) n_placements
    , sum(r.impressions) impressions
    , sum(r.served) served
    , sum(r.cost+r.profit) revenue
    , network_count
from kmn_tag_report r
inner join kmn_layouts l on l.layoutid=r.tagid
inner join kmn_sites using(siteid)
left join (select date(dt) date
    , site
    ,  group_concat(distinct network order by network) network_names
    , count(distinct network) network_count
    from calendar d 
    inner join kmn_available_networks an on an.timestamp < d.dt
    where status=1
    and timestamp >='2015-01-01'
    and dt >='2016-01-01'
    and network in ('pubmatic','pulsepoint','openx','aol')
	group by site, dt) nets 
		on (nets.site=replace(substring_index(l.tag_url,'//',-1),'www.','') and 
        nets.date = r.date)

group by sitename, r.date, clean_url;
        
        

	select date(dt) date
    , site
    ,  group_concat(distinct network order by network)
    , count(distinct network)
    from calendar d 
    inner join kmn_available_networks an on an.timestamp < d.dt
    where status=1
    and site like 'a%'
    and timestamp >='2016-07-01'
    and dt >='2016-09-01'
    and network in ('pubmatic','pulsepoint','openx','aol')
	group by site, dt;
    
select site, network, status, timestamp,date(an.timestamp)
from kmn_available_networks an
where site like 'a%'
and network in ('pubmatic','pulsepoint','openx','aol')
and status=1
