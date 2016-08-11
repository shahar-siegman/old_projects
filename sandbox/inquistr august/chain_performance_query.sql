select cr.placement_id
  	, cr.chain_codes
    , cr.date
    , cr.impressions impressions
    , cr.house
    , locate(concat(':',a.code,':'),concat(':',cr.chain_codes,':')) place
    , a.code tag_code
    , a.entity_type
    , a.served tag_served
    , round(1000*a.income/a.served,2) tag_ecpm
    , a.served/cr.impressions tag_fill_contrib
    , 1000*a.income/cr.impressions tag_rcpm_contrib
    , ktr.impressions placement_impressions

from kmn_chain_report cr
inner join kmn_tag_report ktr on ktr.tagid=cr.placement_id and ktr.date=cr.date
left join (
	select c.tagid placement_id, ad.code,c.date,c.served,c.income, ad.entity_type
    from kmn_cpm c
    inner join kmn_ads_network ad on (c.ads_network_id=ad.id)
    where tagid in (select layoutid from kmn_layouts where siteid='35a97f28bd5020da264fd9dcf23a49c4') 
    -- '03932d66637d396843a00d741fd3808c'
    and c.date >='2016-08-01'
    ) a on 
		  cr.placement_id = a.placement_id 
		    and concat(':',chain_codes,':') like concat('%:',a.code,':%') 
        and a.date=cr.date
where 
  cr.placement_id in (select layoutid from kmn_layouts where siteid='35a97f28bd5020da264fd9dcf23a49c4')
  and cr.date >='2016-08-01'
 order by placement_id, cr.date, impressions desc, place
