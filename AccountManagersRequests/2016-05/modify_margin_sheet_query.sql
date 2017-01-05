SELECT 
    IF(placement_id IS NOT NULL,
        'placement',
        IF(url IS NOT NULL,
			'url',
			IF(sitename IS NOT NULL,
            'site',
            'total'))) row_type,
    IFNULL(a.sitename, '## total ##') sitename,
    IFNULL(a.url, '### Grand Total ###') url,
    IFNULL(a.placement_id, '## total ##') placement_id, 
    IF(a.placement_id IS NULL,
        '',
        placement_name) placement_name,
    if(a.percent_under_optimization=1,'yes','no') is_under_optimization,
--    IFNULL(ROUND(a.revshare_objective, 4), 0) plcmnt_revshare_objective,
    IFNULL(ROUND(b.revshare_objective, 4), 0) url_revshare_objective,
    
    IF(a.placement_id IS NULL,
        '',
        a.optimization_goal_type) optimization_goal_type,
	a.reference_margin/100 current_goal_type_margin,
	'' as new_goal_type,
    '' as new_url_margin,
    -- IFNULL(impressions / 14000, 0) KImps_per_day,
    -- IFNULL(served / 14000, 0) Kserved_per_day,
    ROUND((a.cost + a.profit) * 30 / 14, 0) plcmnt_revenue,
    ROUND(100*(a.cost + a.profit)/(b.cost + b.profit), 0) placement_fraction_in_url,
    -- ROUND(profit * 30 / 14, 0) profit_last_month,
    a.served / a.impressions plcmnt_fill,
    b.served / b.impressions url_fill
    -- 1000 * (a.cost + a.profit) / a.served total_ecpm,
    -- floor_price,
    -- 1 - (a.floor_price * a.served) / (1000 * (a.cost + a.profit)) plcmnt_max_margin
    -- LEAST(1 - (floor_price * a.served) / (1000 * (a.cost + a.profit)),
            -- IFNULL(revshare_objective, 0)) current_revshare
FROM
(
	SELECT 
		s.sitename,
        substring_index(l.tag_url,'//',-1) url,
        l.layoutid placement_id,
        l.name placement_name,
        g.short_name optimization_goal_type,
        g.reference_margin, 
		-- SUM(s.current_revshare * (r.cost + r.profit)) / SUM(r.cost + r.profit) revshare_objective,
        SUM(IF(l.optimization IN (3 , 4, 5), cost + profit, 0)) / SUM(cost + profit) percent_under_optimization,
        SUM(r.impressions) impressions,
        SUM(r.served) served,
        SUM(r.cost) cost,
        SUM(r.profit) profit,
        SUM(l.floor_price * served) / SUM(served) floor_price
    FROM
        kmn_tag_report r
    INNER JOIN 
		kmn_layouts l ON l.layoutid = r.tagid
    INNER JOIN 
		kmn_sites s USING (siteid)
    INNER JOIN 
		tmp_revshare_shahar g using (optimization_goal_id)
    LEFT JOIN 
    (
        SELECT 
        s.tagid layoutid,
        SUBSTRING_INDEX(GROUP_CONCAT(s.revshare
                ORDER BY s.timestamp DESC), ',', 1) current_revshare
		FROM
			kmn_revshare s
		WHERE
			date <= '2016-05-25'
			and s.type='komoona'
		GROUP BY layoutid
	) s USING (layoutid)
    WHERE
        date BETWEEN '2016-05-10' AND '2016-05-23'
    GROUP BY url, placement_id
    HAVING cost + profit > 3
        AND 1000 * (cost + profit) / served > floor_price * 0.90
) a
inner join 
(
	SELECT 
		s.sitename,
        substring_index(l.tag_url,'//',-1) url,
        g.name optimization_goal_type,
        SUM(s.current_revshare * (r.cost + r.profit)) / SUM(r.cost + r.profit) revshare_objective,
        SUM(IF(l.optimization IN (3 , 4, 5), cost + profit, 0)) / SUM(cost + profit) percent_under_optimization,
        SUM(r.impressions) impressions,
        SUM(r.served) served,
        SUM(r.cost) cost,
        SUM(r.profit) profit,
        SUM(l.floor_price * served) / SUM(served) floor_price
    FROM
        kmn_tag_report r
    INNER JOIN 
		kmn_layouts l ON l.layoutid = r.tagid
    INNER JOIN 
		kmn_sites s USING (siteid)
    INNER JOIN 
		kmn_optimization_goal g ON g.id = l.optimization_goal_id
    LEFT JOIN 
    (
        SELECT 
        s.tagid layoutid,
        SUBSTRING_INDEX(GROUP_CONCAT(s.revshare
                ORDER BY s.timestamp DESC), ',', 1) current_revshare
		FROM
			kmn_revshare s
		WHERE
			date <= '2016-05-25'
			and s.type='komoona'
		GROUP BY layoutid
	) s USING (layoutid)
    WHERE
        date BETWEEN '2016-05-10' AND '2016-05-23'
    GROUP BY sitename, url
    HAVING cost + profit > 3
        AND 1000 * (cost + profit) / served > floor_price * 0.90
) b using(sitename, url)
