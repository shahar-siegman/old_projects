select ao.*, 
	round(if(publisher_revenue_change<0, -sqrt(-publisher_percent_change)*publisher_revenue_change, null),0) revenue_negative_change_score,
    round(if(publisher_revenue_change>0, sqrt(publisher_percent_change)*publisher_revenue_change, null),0) revenue_positive_change_score 
from
(
	SELECT 
		IFNULL(b.sitename, '## total ##') sitename,
		IFNULL(b.url, '### Grand Total ###') url,
		placement_count,
		placement_goal_types,
		IFNULL(ROUND(b.revshare_objective, 4), 0) url_revshare_objective,
		-- rs_b.name url_matching_opt_type,
		revshare_after_change,
		b.percent_under_optimization url_percent_under_optimization,
		-- IFNULL(impressions / 14000, 0) KImps_per_day,
		-- IFNULL(served / 14000, 0) Kserved_per_day,
		ROUND((b.cost + b.profit) * 30 / 14, 0) url_revenue,
		-- ROUND(profit * 30 / 14, 0) profit_last_month,
		b.served / b.impressions url_fill,
		-- 1000 * (a.cost + a.profit) / a.served total_ecpm,
		-- floor_price,
		round(if (b.percent_under_optimization<0.2, null,(b.cost + b.profit) * 30 / 14*(b.revshare_objective-revshare_after_change)/100),0) publisher_revenue_change, 
		round(if (b.percent_under_optimization<0.2, null,b.revshare_objective-revshare_after_change),0) publisher_percent_change
	FROM
	(
		SELECT 
			s.sitename,
			substring_index(l.tag_url,'//',-1) url,
			g.name optimization_goal_type,
			SUM(s.current_revshare * (r.cost + r.profit)) / SUM(r.cost + r.profit) revshare_objective,
			sum((r.cost+r.profit)*rs.reference_margin) / sum(r.cost+r.profit) revshare_after_change,
			SUM(IF(l.optimization IN (3 , 4, 5), cost + profit, 0)) / SUM(cost + profit) percent_under_optimization,
			SUM(r.impressions) impressions,
			SUM(r.served) served,
			SUM(r.cost) cost,
			SUM(r.profit) profit,
			SUM(l.floor_price * served) / SUM(served) floor_price,
			count(distinct r.tagid) placement_count,
			group_concat(distinct rs.short_name) placement_goal_types
		FROM
			kmn_tag_report r
		INNER JOIN 
			kmn_layouts l ON l.layoutid = r.tagid
		INNER JOIN 
			kmn_sites s USING (siteid)
		inner join 
			tmp_revshare_shahar rs using (optimization_goal_id)
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
	) b 
) ao