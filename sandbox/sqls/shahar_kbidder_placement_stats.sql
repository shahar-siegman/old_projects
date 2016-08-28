select * from (		
select tagid placement_id		
		, date		
        , sum(r.impressions) tag_impressions		
        , sum(r.served) tag_served		
        , sum(r.cost+r.profit) tag_revenue		
	from kmn_tag_report r	
	where tagid in (select layoutid from kmn_layouts where siteid='544cc947ba95315f5f8b03a95fd790d3')	
	and date='2016-08-19'	
    group by placement_id, date) a		
join		
	(select placement_id	
		, date(hour) date
		, sum(impressions) estimated_impressions
        , sum(estimated_served) estimated_served		
        , sum(estimated_profit+estimated_cost) estimated_revenue		
    from kmn_report_estimation_placement_hourly		
    where placement_id in (select layoutid from kmn_layouts where siteid='544cc947ba95315f5f8b03a95fd790d3')		
    and hour between '2016-08-19 00:00' and '2016-08-19 23:59'		
    group by placement_id, date		
    ) b using (placement_id, date)	