SELECT 
    IF(placement_id IS NOT NULL,
        'placement',
        IF(url IS NOT NULL,
			'url',
			IF(sitename IS NOT NULL,
            'site',
            'total'))) row_type,
    IFNULL(a.username, '### Grand Total ###') username,
    IFNULL(a.sitename, '## total ##') sitename,
    IFNULL(a.placement_id, '## total ##') placement_id,
    IF(a.placement_id IS NULL,
        '',
        placement_name) placement_name,
    IFNULL(ROUND(revshare_objective, 4), 0) revshare_objective,
    IFNULL(percent_under_optimization, 0) percent_under_optimization,
    IFNULL(impressions / 14000, 0) KImps_per_day,
    IFNULL(served / 14000, 0) Kserved_per_day,
    ROUND((cost + profit) * 30 / 14, 0) revenue_last_month,
    ROUND(profit * 30 / 14, 0) profit_last_month,
    a.served / a.impressions fill,
    1000 * (a.cost + a.profit) / a.served total_ecpm,
    floor_price,
    IF(a.placement_id IS NULL,
        '',
        optimization_goal_type) optimization_goal_type,
    1 - (floor_price * a.served) / (1000 * (a.cost + a.profit)) max_margin,
    LEAST(1 - (floor_price * a.served) / (1000 * (a.cost + a.profit)),
            IFNULL(revshare_objective, 0)) current_revshare
FROM
(
	SELECT 
		s.sitename,
        substring_index(l.tag_url,'//',-1) url,
        l.layoutid placement_id,
        l.name placement_name,
        g.name optimization_goal_type,
        SUM(s.current_revshare * (r.cost + r.profit)) / (100 * SUM(r.cost + r.profit)) revshare_objective,
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
			date <= '2016-05-05'
			and s.type='komoona'
		GROUP BY layoutid
	) s USING (layoutid)
    WHERE
        date BETWEEN '2016-04-22' AND '2016-05-05'
    GROUP BY sitename, url, placement_id WITH ROLLUP
    HAVING cost + profit > 3
        AND 1000 * (cost + profit) / served > floor_price * 0.90
) a