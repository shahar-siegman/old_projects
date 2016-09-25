select tagid
	, date
    , an.code
    , impressions
    , served
from kmn_cpm c
inner join kmn_ads_network an on an.id=c.ads_network_id
where timestamp between unix_timestamp('2016-09-11') and unix_timestamp('2016-09-16')