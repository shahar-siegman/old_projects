select s.sitename,replace(substring_index(l.tag_url,'//',-1),'www.','') domain, 
	concat(l.ad_width,'x', l.ad_height) size, 
    placement_id, 
    network,
    total_impressions, 
    external_wins,
    external_wins*avg_external_win_cpm/1000 revenue,
    round(total_impressions/external_wins) Kimps_for_1000_wins,
    round(least(1, 250/external_wins, 100000/total_impressions),3) hex2_sample_for_1000_wins,
    if(total_impressions/external_wins < 100000/50  AND external_wins >50,'yes','no') is_viable
from kmn_kbidder_placement_network_daily_data dd
inner join kmn_layouts l on l.layoutid =dd.placement_id
inner join kmn_sites s using(siteid)
where day = '2017-05-11'
and network = 'sovrn'
and total_impressions > 10000
and total_impressions/external_wins < 100000/50  AND external_wins >50
order by sitename, domain,size, placement_id