select date
	, type
    , sum(impressions) impressions
	, sum(served) served
    , sum(income) revenue
    , count(distinct ads_network_id) distinct_adtags
    , count(distinct tagid) distinct_placements
from kmn_cpm
where timestamp between unix_timestamp('2016-07-01') and unix_timestamp('2016-07-23')
group by date, type;