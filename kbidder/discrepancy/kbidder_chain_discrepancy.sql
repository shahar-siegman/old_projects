select sitename
	, name
    , layoutid
    , if(name like '%desktop%','desktop',if(name like '%mobile%','mobile','unknown')) device
    , goal_type
    , replace(substring_index(tag_url,'//',-1),'www.','') url
	, date
    , impressions_with_wins wins
    , chain_impressions `chain impressions` 
  	, concat(round(100.0 * (1- chain_impressions /impressions_with_wins), 2), '%') `win to chain discrep`
    , concat(round(100.0 * adtag_served / chain_impressions, 2), '%') `adtag fill`
    , concat(round(100.0 * postbid_served / chain_impressions, 2), '%') `postbid fill`
    , concat(round(100.0 * hbtag_served / chain_impressions, 2), '%') `hb fill`
    , concat(round(100.0 * (1- hbtag_served / (chain_impressions-adtag_served-postbid_served)), 2), '%') `chain to hb discrep`
    , ifnull(concat('$', round(1000 * adtag_revenue / adtag_served, 2)),'') `adtag ecpm`
    , ifnull(concat('$',round(1000 * postbid_revenue / postbid_served, 2)),'') `postbid ecpm`
    , ifnull(concat('$',round(1000 * hbtag_revenue / hbtag_served, 2)),'') `hb ecpm`     
from (
	select s.sitename
		, s.siteid
		, l.layoutid
        , l.name
        , elt(l.optimization_goal_id,'A','B','C','A+','C+','G','G-','Kbidder','Max Fill Low FP')  goal_type
		, c.date
        , l.tag_url
		, sum(cn.impressions)-sum(pt.pt_chain_imps) chain_impressions
		, sum(c.adtag_served) adtag_served
        , sum(c.hbtag_served) hbtag_served
        , sum(c.postbid_served) postbid_served
   		, sum(c.adtag_revenue) adtag_revenue
        , sum(c.hbtag_revenue) hbtag_revenue
        , sum(c.postbid_revenue) postbid_revenue
        , sum(c.hbtag_impressions) hbtag_impressions
        , sum(pt.pt_chain_imps) pt_chain_imps
        , sum(impressions_with_wins) impressions_with_wins
	from kmn_layouts l
	inner join kmn_sites s using(siteid)
   	inner join (
		select tagid
			, date
			, sum(if(an.entity_type='adtag',cpm.served,0)) adtag_served
			, sum(if(an.entity_type='hbtag',cpm.served,0)) hbtag_served
			, sum(if(an.entity_type='postbid',cpm.served,0)) postbid_served
			, sum(if(an.entity_type='adtag',cpm.income,0)) adtag_revenue
			, sum(if(an.entity_type='hbtag',cpm.income,0)) hbtag_revenue
			, sum(if(an.entity_type='postbid',cpm.income,0)) postbid_revenue
			, sum(if(an.entity_type='hbtag',cpm.impressions,0)) hbtag_impressions
        from kmn_cpm cpm force index (idx_timestamp)
        inner join kmn_ads_network an on an.id=cpm.ads_network_id
        inner join kmn_layouts on kmn_layouts.layoutid=cpm.tagid
        where tagid in (Select layoutid from kmn_layouts where placement_kind='kbidder')
        and cpm.timestamp >= unix_timestamp(current_date) -7*24*3600
        group by tagid, date) c on c.tagid=l.layoutid
	inner join (
		select placement_id,date,sum(impressions) impressions
		from kmn_chain_report
		where placement_id in (Select layoutid from kmn_layouts where placement_kind='kbidder')
		and date>=subdate(current_date, 14)
		group by placement_id, date) cn on (cn.placement_id=l.layoutid and cn.date=c.date)
	left join (
		select placement_id
			, date(hour) date
            , sum(no_bid_position_impressions_with_wins) pt_chain_imps
            , sum(impressions_with_wins) impressions_with_wins
        from kmn_kbidder_data
        where hour >= subdate(current_date, 7)
        group by placement_id, date(hour) ) pt on (pt.placement_id=l.layoutid and pt.date=c.date)
	group by s.sitename, l.layoutid, c.date
) a
where siteid='3981089c6367bb9381013a3c3f040cf9'
order by sitename, date desc