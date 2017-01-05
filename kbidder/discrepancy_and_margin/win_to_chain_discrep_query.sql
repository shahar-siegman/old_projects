select sitename 
	, a.name
	, domain 
	, date 
	, a.layoutid placement_id
    , impressions_with_wins wins
    , chain_impressions `chain impressions` 
from (
	select s.sitename
  		, l.name
  		, l.layoutid
		, replace(substring_index(l.tag_url,'//',-1),'www.','') domain
        , cn.date
		, sum(cn.impressions)-sum(pt.pt_chain_imps) chain_impressions
        , sum(pt.pt_chain_imps) pt_chain_imps
        , sum(impressions_with_wins) impressions_with_wins
	from kmn_layouts l
	inner join kmn_sites s using(siteid)
	inner join (
		select placement_id,date,sum(impressions) impressions
		from kmn_chain_report
		where placement_id in (Select layoutid from kmn_layouts where placement_kind='kbidder')
		and date>=subdate(current_date, 21)
		group by placement_id, date) cn on (cn.placement_id=l.layoutid)
	left join (
		select placement_id
			, date(hour) date
            , sum(no_bid_position_impressions_with_wins) pt_chain_imps
            , sum(impressions_with_wins) impressions_with_wins
        from kmn_kbidder_data
        where hour >= subdate(current_date, 21)
        group by placement_id, date(hour) ) pt on (pt.placement_id=l.layoutid and pt.date=cn.date)
	group by l.layoutid, cn.date
) a
where chain_impressions>200

order by domain, date desc, placement_id