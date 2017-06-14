select sitename, 
	replace(substring_index(l.tag_url,'//',-1),'www.','') domain, 
	group_concat(distinct ifnull(elt(l.optimization_goal_id,'A','B','C','A+','C+','G','G-','Kbidder','Max Fill Low FP'),og.name) order by l.optimization_goal_id) goal_type,
	sum(t.impressions) impressions, 
    sum(t.served) served, 
    count(t.tagid) n_placements,
    concat(round(100*sum(t.served)/sum(t.impressions),2),'%') fill,
    round(sum(t.revenue), 2) revenue,
    round(sum(t.profit), 2) profit,
    concat(round(100*sum(t.profit)/sum(t.revenue),1),'%') effective_revshare
from kmn_layouts l
inner join kmn_sites s using(siteid)
inner join kmn_optimization_goal og on og.id = l.optimization_goal_id
inner join (
	select tagid, 	
		   round(sum(impressions)/7) impressions, 
           round(sum(served)/7) served, 
           sum(cost+profit)/7 revenue, 
           sum(profit)/7 profit
    from kmn_tag_report 
    where date between '2017-05-19' and '2017-05-25'
    and impressions > 100
    group by tagid) t on t.tagid= l.layoutid
group by siteid, replace(substring_index(l.tag_url,'//',-1),'www.','')
having impressions > 1000 and revenue >1
order by impressions desc