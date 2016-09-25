select tagid
	, an.type
	, substring(script, locate('"ssp_placementid":', script) + 19, locate('"', script, locate('"ssp_placementid":', script) + 20) - (locate('"ssp_placementid":', script) + 19)) as ssp_placement_id
	, substring(script, locate('"tag_name":', script) + 12, locate('"', script, locate('"tag_name":', script) + 13) - (locate('"tag_name":', script) + 12)) as tag_name
    , an.code
    , min(date) tag_start_date
    , max(if(served>3,date,'2015-01-01')) last_served_date
    , sum(if(served<3,impressions,0)) unserved_impressions
	, max(date) last_day_with_impression
    , sum(impressions) impression
    , sum(served) served
    , sum(income) lifetime_income
    , 1000*sum(income)/sum(served) liftime_average_ecpm
    , kmn_floor latest_floor_price
from kmn_cpm c force index (idx_timestamp)
inner join kmn_ads_network an on (an.id=c.ads_network_id)
-- inner join (select tagid,sum(impressions) imps from kmn_tag_report where date>'2016-07-01' group by tagid having imps> 1000000) a using(tagid)
where timestamp >= unix_timestamp('2016-07-01')
group by an.type, tagid, an.id, an.code
having last_day_with_impression>='2016-09-12'
and last_served_date < '2016-08-01'
and unserved_impressions > 10000
order by tagid, last_served_date, an.code;


select tagid
	, an.id
    , an.code
    , min(date) min_date
    , max(date) max_date
    , sum(impressions) imps
    , sum(served) served
    , sum(if(served<3,impressions,0)) unserved_impressions
    , sum(served)/sum(impressions) fill
from kmn_cpm c force index (idx_timestamp)
inner join kmn_ads_network an on (an.id=c.ads_network_id)
-- inner join (select tagid,sum(impressions) imps from kmn_tag_report where date>'2016-07-01' group by tagid having imps> 1000000) a using(tagid)
where timestamp >= unix_timestamp('2016-07-01')
group by tagid, an.id, an.code
having fill <0.02
and unserved_impressions > 5000
and max_date >='2016-09-12'

