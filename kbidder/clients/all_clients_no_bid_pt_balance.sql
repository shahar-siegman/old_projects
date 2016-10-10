
select tagid,no_bid_chain, p.date, p.impressions kmn_cpm_impressions, p.served kmn_cpm_served, d.pt_imps,d.pt_win_imps, d.pt_win_cost, revenue,
	 cr.impressions chain_imps, cr.served chain_served
from (
	select ch.tagid, ch.no_bid_chain, c.date, max(c.impressions) impressions, sum(c.served) served, sum(c.income) revenue
	from (
		select tagid
		, concat(','
			, replace(
				substring(optimization_result,instr(optimization_result,'"chains"')+11, instr(optimization_result,'"weights"')-instr(optimization_result,'"chains"')-14)
				, '"'
				, '')
			, ',') with_bid_chain
		, concat(','
			, replace(
				substring(
					optimization_result
					, instr(optimization_result,'"mainChainConfiguration":{"codes"')+35
					, locate(
						'"force"'
						, optimization_result
						, instr(optimization_result,'"mainChainConfiguration":{"codes"')
						) 
					- instr(optimization_result,'"mainChainConfiguration":{"codes"') -37
					) 
				, '"'
				, '')
			,',') no_bid_chain
		from kmn_serving_trees t
		where rules= '[{"ruletype" : "bids","rulevalues":{"type":"existence","value":true}}]'
		) ch
	inner join kmn_ads_network an on (an.layoutid = ch.tagid and  ch.no_bid_chain like concat('%,',an.code,',%'))
	inner join kmn_cpm c on c.ads_network_id = an.id and c.tagid=an.layoutid
	where c.timestamp >= unix_timestamp('2016-09-16')
	group by tagid, date ) p
inner join
	(select placement_id
		, date(hour) date
        , sum(no_bid_position_impressions) pt_imps
        , sum(no_bid_position_impressions_with_wins) pt_win_imps
        , sum(no_bid_position_total_win_cpm) pt_win_cost
    from kmn_kbidder_data 
    where hour >='2016-09-16'
    group by placement_id, date
    ) d on (p.tagid=d.placement_id and d.date=p.date)
left join kmn_chain_report cr on (d.placement_id = cr.placement_id and d.date=cr.date and replace(p.no_bid_chain,',',':')=concat(':',chain_codes,':'))
