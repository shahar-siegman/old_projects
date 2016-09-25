select 
  placement_id
  , geo_country
  , case when ua_device_type='M' then 'Mobile' else ua_device_type end device
  ,  final_state
  , case when length(pbsbids)>5 then least(floor( json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2)/100)*100,5000) else 10000 end first_bid_ts
  , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1) kb_win_network
  , json_extract_path_text(a.hdbd_json,'o','rests') aol_response_time
  , json_extract_path_text(a.hdbd_json,'l','rests') cpx_response_time
  , json_extract_path_text(a.hdbd_json,'p','rests') pubmatic_response_time
  , json_extract_path_text(a.hdbd_json,'S','rests') Sovrn_response_time
  , json_extract_path_text(a.hdbd_json,'o','cpm') aol_bid
  , json_extract_path_text(a.hdbd_json,'l','cpm') cpx_bid
  , json_extract_path_text(a.hdbd_json,'p','cpm') pubmatic_bid
  , json_extract_path_text(a.hdbd_json,'S','cpm') Sovrn_bid
  , json_extract_path_text(a.hdbd_json,'o','reqts') aol_request_time
  , json_extract_path_text(a.hdbd_json,'l','reqts') cpx_request_time
  , json_extract_path_text(a.hdbd_json,'p','reqts') pubmatic_request_time
  , json_extract_path_text(a.hdbd_json,'S','reqts') Sovrn_request_time
  , served_chain
  , case when length(kb_sold_cpm)>0 then 1 else 0 end kb_wins
  , case when length(a.served_tag)<2 then 0 else 1 end served
  , case when a.served_tag='h' then 1 else 0 end house
  , case when a.served_tag='' and a.timestamp_placement is null then '' when a.served_tag='' and a.timestamp_placement is not null then 'Unknown' when a.served_tag='h' then '' when strpos(a.hdbd_json, a.served_tag) = 0 then 'chain' else 'hdbd' end served_tag_source
  , md5(url) url_md5
  , served_tag_network
  , kb_sold_cpm
from aggregated_logs_5 a
where placement_id in ('1f35efc8e8197aaacfc7482a8be19366','842f96cba234a0739590b83a613bdfa9','f3ef1de52ef7a6d0221891066c3cf084','05364e0e1f4ae3ee25df19299e4dcbf9','dd36f40d4517a352b9f954e3ccd9838c','7030b2fc683dc4c36d9f10398f82b546','5eb8982daf7f6ee2bb9b4a9166c7c47a','ef5576221abe0963bdafcb9149050d11','4d68d237a94c8b29b44f7400a6a45b81','d355e0e2cab8f41ce2b3e4174b405581','d2c3482d071eca71d10e0208daa365f5','8724c4883c80a579dbaa4c95a5cc9db4')
and timestamp between '2016-09-11 11:00' and '2016-09-11 12:00';
length(a.hdbd_json)>5;

select hdbd_json
from aggregated_logs_5 a
where placement_id='1f35efc8e8197aaacfc7482a8be19366'
and timestamp between '2016-09-11 11:00' and '2016-09-11 12:00'
and length(a.hdbd_json)>5
limit 100;
