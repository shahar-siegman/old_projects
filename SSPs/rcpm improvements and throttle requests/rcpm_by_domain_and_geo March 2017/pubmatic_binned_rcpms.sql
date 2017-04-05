select month_of_year,
	network,
    placement_kind,
    web_mobile,
    rcpm_bin,
    impression_count_bin,
    sum(impressions_) impressions,
    sum(served_) served,
    sum(revenue_) revenue,
	count(distinct layoutid) distinct_placements,
	count(distinct ads_network_id) distinct_tags,
	count(distinct siteid) distinct_accounts
from (
	SELECT 
		month(date) month_of_year,
		c.ads_network_id,
        l.layoutid,
        l.siteid,
		c.type network,
		l.placement_kind,
		l.type web_mobile,
		concat(l.ad_width,'x',l.ad_height) ad_size,
		SUM(impressions) impressions_,
		SUM(served) served_,
		sum(income) revenue_,
        round(1000*SUM(income)/sum(impressions),2) rcpm_bin,
        least(round(sum(impressions),-3), 10000) impression_count_bin
		-- floor(1000*SUM(income)/sum(ifnull(impressions,1))/ if((1000*SUM(income)/sum(ifnull(impressions,1)))<0.011,0.001,0.025))*if((1000*SUM(income)/sum(ifnull(impressions,1)))<0.011,0.001,0.025) rcpm_bin
	FROM
		kmn_cpm c -- force index (idx_timestamp)
			INNER JOIN
		kmn_layouts l ON l.layoutid = c.tagid
			-- inner join 	shahar_placement_lists pl on pl.placement_id = l.layoutid and pl.list_id=6
	WHERE
		timestamp >= UNIX_TIMESTAMP('2016-12-01')
		and c.type='openx'
        and (c.impressions >0 or c.impressions is null)
	GROUP BY month_of_year, c.ads_network_id 
    having impressions_ > 10
) a
group by  month_of_year, network, placement_kind, web_mobile, rcpm_bin, impression_count_bin