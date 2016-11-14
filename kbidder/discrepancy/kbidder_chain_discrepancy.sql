select sitename
	, date
    , chain_impressions
    , concat(round(100.0 * adtag_served / chain_impressions, 2), '%') adtag_fill
    , concat(round(100.0 * postbid_served / chain_impressions, 2), '%') postbid_fill
    , concat(round(100.0 * postbid_served / chain_impressions, 2), '%') postbid_fill
from (
	select s.sitename
		, c.date
		, sum(cn.impressions) chain_impressions
		, sum(if(an.entity_type='adtag',c.served,0)) adtag_served
		, sum(if(an.entity_type='hbtag',c.served,0)) hbtag_served
		, sum(if(an.entity_type='postbid',c.served,0)) postbid_served
		, sum(if(an.entity_type='hbtag',c.impressions,0)) hbtag_impressions
		, sum(c.income) income   
	from kmn_layouts l
	inner join kmn_sites s using(siteid)
	inner join kmn_cpm c force index(fk_tag_cpm_idx) on (c.tagid=l.layoutid)
	inner join kmn_ads_network an on an.id=c.ads_network_id
	inner join (
		select placement_id,date,sum(impressions) impressions
		from kmn_chain_report
		where placement_id in (Select layoutid from kmn_layouts where placement_kind='kbidder')
		and date>='2016-10-01'
		group by placement_id, date) cn on (cn.placement_id=l.layoutid and cn.date=c.date)
	where c.timestamp >= unix_timestamp('2016-10-01')
	and c.tagid in (Select layoutid from kmn_layouts where placement_kind='kbidder')
	group by s.sitename, c.date
) a