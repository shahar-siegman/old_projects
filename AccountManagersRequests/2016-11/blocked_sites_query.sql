select s.sitename
	, if(sitename like 'haven marketing%' or sitename like 'inspirus media%' or replace(substring_index(l.tag_url,'//',-1),'www.','') in ('mytrendyhome.com','mensocietymag.com',
    'bitbytelife.com','autotuneonline.com','lifeluxe.com','fitnessrestored.com','comfycozyabode.com'),'blocked','') is_blocked
	, replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
    , l.name
    , l.layoutid
    , 1000*sum(r.cost+r.profit)/sum(r.served) ecpm
	, elt(l.optimization_goal_id,'A','B','C','A+','C+','G','G-','Kbidder','Max Fill Low FP','suspicious') goal_Type
    , sum(r.cost+r.profit) revenue
    , sum(profit)/sum(r.cost+r.profit) recent_margin
    , l.floor_price
from kmn_layouts l
inner join kmn_tag_report r on (r.tagid=l.layoutid)
inner join kmn_sites s using(siteid)
where r.date between '2016-11-06' and '2016-11-12'
and l.placement_kind is null
group by l.layoutid
having revenue > 2;

