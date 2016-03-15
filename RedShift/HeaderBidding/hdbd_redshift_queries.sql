select d.*
, CASE WHEN impressions <= 0 THEN 0 ELSE 1.0 * served / impressions END fill
, CASE WHEN impressions <= 0 THEN 0 ELSE 1.0 * hb_served / impressions END hb_fill
, CASE WHEN served <= 0 THEN 0 ELSE 1.0 * hb_served / served END hb_served_percent
from
  (select
  c.placement_id
  , date_trunc('hour', c.timestamp) AS hour
  , count(c.timestamp_hb_pl) hb_impressions
  , count(c.timestamp_tag) impressions
  , count(nullif(is_served, false)) served
  --, fill
  , count(nullif(is_hb_served, false)) hb_served
  --, hb_served_percent, hb_fill
from (select a.placement_id, a.timestamp, a.timestamp_hb_pl, a.timestamp_tag
              ,length(a.served_tag) > 1 as is_served
              ,a.hdbd_json is not null AND strpos(a.hdbd_json, a.served_tag) > 0 AND length(a.served_tag) > 1 as is_hb_served
from aggregated_logs_5 a
  WHERE length(a.hdbd_json) > 1
  AND a.timestamp >= '2016-02-21 00:00:00.000000'
--limit 1000
     ) c
group by c.placement_id, hour) d;
