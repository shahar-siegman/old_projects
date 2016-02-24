select if(placement_id is not null, 'placement', if(sitename is not null, 'site', if(username is not null, 'user', 'total'))) row_type 
	, ifnull(a.username,'### Grand Total ###') username
    , ifnull(a.sitename,'## total ##') sitename
    , ifnull(a.placement_id,'## total ##') placement_id
    , if(a.placement_id is null, '', placement_name) placement_name
    , ifnull(margin_objective,0) margin_objective
    , ifnull(percent_under_optimization,0) percent_under_optimization
    , ifnull(impressions/14000,0) KImps_per_day
    , ifnull(served/140000,0) Kserved_per_day
    , round((cost + profit)*30/14,0) revenue_last_month
    , round(profit*30/14,0) profit_last_month
	, a.served/ a.impressions fill
    , 1000*(a.cost+a.profit) / a.served total_ecpm
    , if(a.placement_id is null, '', optimization_goal_type) optimization_goal_type
    , 1 - (floor_price * a.served ) / (1000* (a.cost + a.profit)) max_margin
	, least(
		1 - (floor_price * a.served ) / (1000* (a.cost + a.profit))
		, ifnull(margin_objective,0)
		) 
		current_margin
from (
	select s.username
	, s.sitename
	, l.layoutid placement_id
    , l.name placement_name
    , g.name 		optimization_goal_type
    , sum(g.margin_goal*(r.cost+r.profit))/sum(r.cost+r.profit)	margin_objective
    , sum(if(l.optimization in (3,4,5), cost+profit,0)) / sum(cost+profit) percent_under_optimization
	, sum(r.impressions) impressions
    , sum(r.served) served
    , sum(r.cost) cost
    , sum(r.profit) profit
    , sum(l.floor_price * served)/sum(served) floor_price
	from kmn_tag_report r
	inner join kmn_layouts l on l.layoutid = r.tagid
	inner join kmn_sites s using(siteid)
	inner join kmn_optimization_goal g on g.id = l.optimization_goal_id
	where date between '2016-02-01' and '2016-02-14'
    group by username, sitename, placement_id with rollup
    having cost+profit > 3 and 1000*(cost+profit)/served > floor_price*0.8
	) a
    
#order by username, sitename, placement_id
;

substring_index(group_concat(revshare order by timestamp),',',-1) 

select r.tagid
	, datediff(date,'${start_date}') new_revshare_date
 	, substring_index(group_concat(revshare order by timestamp),',',-1)  as new_revshare 
from kmn_revshare r 
where date>='2015-01-01'
group by tagid, date;