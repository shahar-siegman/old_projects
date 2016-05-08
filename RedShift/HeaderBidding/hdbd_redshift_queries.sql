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
     ) c
group by c.placement_id, hour) d;



select a.placement_id
  , a."timestamp"
  , a.cb
  , a.client_ip
  , a.hdbd_time
  , replace(a.hdbd_json,',','!') hdbd_json /* replace commas for csv-safe string */
  , json_extract_path_text(a.hdbd_json,'l','cpm') cpx_bid
  , json_extract_path_text(a.hdbd_json,'o','cpm') aol_bid
  , json_extract_path_text(a.hdbd_json,'j','cpm') index_bid
  , json_extract_path_text(a.hdbd_json,'p','cpm') pubmatic_bid
  , json_extract_path_text(a.hdbd_json,'S','cpm') sovrn_bid
  , case when b.served_tag_network='e' and b.cpm>0 then b.cpm else null end openx_bid
  , case when length(b.served_tag)>=2 then 1 else 0 end is_served
  , case when json_extract_path_text(a.hdbd_json, b.served_tag_network,'cpm') > 0 or b.served_tag_network='e' and b.cpm>0 then b.served_tag_network else null end served_hdbd_network
  , b.served_tag
  , b.cpm
from aggregated_logs_5 a
inner join (
  select placement_id, "timestamp", cb, client_ip, served_tag, served_tag_network, cpm, hdbd_json
  from aggregated_logs_5
  where 
  placement_id='b099e27c6d929509f67c5a04cca99000'
  and 
  timestamp between '2016-05-02 11:00:00' and '2016-05-02 12:00:00'
  and length(served_tag)>0
) b using(placement_id, "timestamp",cb,client_ip)
where 
a.placement_id='b099e27c6d929509f67c5a04cca99000'
and a.timestamp between '2016-05-02 11:00:00' and '2016-05-02 12:00:00'
and length(a.hdbd_json)>0
;

