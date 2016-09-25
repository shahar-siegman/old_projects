select 
  placement_id
  , geo_country
  , case when ua_device_type='M' then 'Mobile' else ua_device_type end device
  ,  final_state
  , case when length(pbsbids)>5 then least(floor( json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2)/100)*100,5000) else 10000 end first_bid_ts
  , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1) kb_win_network1
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid') kb_sent_bid1
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts') kb_sent_bid_ts1
  , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'code'),1) kb_win_network2
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'sent_bid') kb_sent_bid2
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'bid_ts') kb_sent_bid_ts2
  , json_extract_path_text(a.hdbd_json,'o','rests') aol_response_time
  , json_extract_path_text(a.hdbd_json,'l','rests') cpx_response_time
  , json_extract_path_text(a.hdbd_json,'p','rests') pubmatic_response_time
  , json_extract_path_text(a.hdbd_json,'o','cpm') aol_bid
  , json_extract_path_text(a.hdbd_json,'l','cpm') cpx_bid
  , json_extract_path_text(a.hdbd_json,'p','cpm') pubmatic_bid
  , json_extract_path_text(a.hdbd_json,'o','reqts') aol_request_time
  , json_extract_path_text(a.hdbd_json,'l','reqts') cpx_request_time
  , json_extract_path_text(a.hdbd_json,'p','reqts') pubmatic_request_time
  , case when strpos(a.hdbd_json, a.served_tag) = 1 and length(served_chain)>=4 then left(served_chain,length(served_chain)-3) else served_chain end served_chain_without_hb_tag
  , served_chain
  , replace(original_chain,',','|') orig_chain
  , chain
  , case when length(kb_sold_cpm)>0 then 1 else 0 end kb_wins
  , case when length(a.served_tag)<2 then 0 else 1 end served
  , case when a.served_tag='h' then 1 else 0 end house
  , case when a.served_tag='' and a.timestamp_placement is null then '' when a.served_tag='' and a.timestamp_placement is not null then 'Unknown' 
      when a.served_tag='h' then '' when strpos(a.hdbd_json, a.served_tag) = 0 then 'chain' else 'hdbd' end served_tag_source
  , url
  , served_tag_network
  , kb_sold_cpm
  , cpm
from impressions a
where placement_id in ('0b2b1e012751fe245e12c4e8559f2384',
'1f4910d4c6598ced96834e2b8ed19e62',
'39a26bc7eb47383e1053c17c83222326',
'a21fc9eb47a677b9888cb6e0e2485ab5',
'f1942acbae21ba02349d8616070f5264',
'fea197961cf5984193fbe9a0a339e015')
and timestamp between '2016-09-19 11:00' and '2016-09-20 11:00'
;
length(a.hdbd_json)>5;

select hdbd_json, pbsbids
from impressions a
where placement_id='4afaa36d35278586ce12f73d4d57ec03'
and timestamp between '2016-09-11 11:00' and '2016-09-11 12:00'
and length(a.hdbd_json)>5 
limit 100;
