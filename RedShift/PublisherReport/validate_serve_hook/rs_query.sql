select placement_id
  , date_trunc('day',timestamp) date_
  ,chain
  , served_tag
  , served_tag_network
  , count(1) cnt 
  , sum(case when geo_country='US' then 1 else 0 end) country_us
  , sum(case when ua_device_type='NoMobileNoTablet' then 1 else 0 end) nonmobile
from impressions
where timestamp between '2016-09-11' and '2016-09-16'
-- and placement_id in (select distinct placement_id from impressions limit 100)

group by placement_id, date_, chain, served_tag, served_tag_network
