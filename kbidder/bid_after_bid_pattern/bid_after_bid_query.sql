select
  uid
  , cb
  , "timestamp"
  , placement_id
  , case when length(pbsbids)>5 then least(floor( json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2)/100)*100,5000) 
 else 10000 end first_bid_ts
  , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1) kb_win_network
  , json_extract_path_text(a.hdbd_json,'o','cpm') aol_bid
  , json_extract_path_text(a.hdbd_json,'l','cpm') cpx_bid
  , json_extract_path_text(a.hdbd_json,'p','cpm') pubmatic_bid
  , json_extract_path_text(a.hdbd_json,'o','rests') aol_response_time
  , json_extract_path_text(a.hdbd_json,'l','rests') cpx_response_time
  , json_extract_path_text(a.hdbd_json,'p','rests') pubmatic_response_time
  , json_extract_path_text(a.hdbd_json,'o','reqts') aol_request_time
  , json_extract_path_text(a.hdbd_json,'l','reqts') cpx_request_time
  , json_extract_path_text(a.hdbd_json,'p','reqts') pubmatic_request_time
  , served_tag_network
  , case when a.served_tag='' then '' when a.served_tag='h' then 'h' when strpos(a.hdbd_json, a.served_tag) = 0 then 'chain' else 'hdbd' end served_tag_source
  , md5(url) url_md5
from aggregated_logs_5 A
where 
  placement_id in ('5c312e17f768c831ac20170cd6386f8b', '3fe0fd006d3c2a96533c0378ffba323f', '3e5cb1662bb51da0795e48977826d427')
    --('0fdf1dfdd6555b461045aefec232050b','17e6f86dde3326893a73995be79bb46e','741aebc4a3619038194cb581247f19eb','8e95a19fc3718823e882d3fa9b89e88c')
  and length(pbsbids)>5
  and length(uid) >5
  and timestamp >= '2016-07-30 07:00'
  and length(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid'))>2
 order by uid, "timestamp", placement_id
 limit 5000;
