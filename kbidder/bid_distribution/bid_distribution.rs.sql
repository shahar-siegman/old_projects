select  a.placement_id,
  cb,
  "timestamp",
  geo_country,
  ua_device_type,
  case when second_sent_bid_ts='' and first_sent_bid_ts='' then '0'
    when second_sent_bid_ts='' and first_sent_bid_ts::decimal(8,2) < estimated_timeout then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')
    when second_sent_bid_ts='' then '0'
    when second_sent_bid_ts::decimal(8,2) < estimated_timeout then json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'sent_bid')
    when first_sent_bid_ts::decimal(8,2) < estimated_timeout then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')
    else '0'
  end bid_sent,
  case when second_sent_bid_ts='' and first_sent_bid_ts='' then ''
    when second_sent_bid_ts='' and first_sent_bid_ts::decimal(8,2) < estimated_timeout then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')
    when second_sent_bid_ts='' then ''
    when second_sent_bid_ts::decimal(8,2) < estimated_timeout then json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'bid_src')
    when first_sent_bid_ts::decimal(8,2) < estimated_timeout then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')
    else ''
  end bid_source,
  kb_code,
  case when kb_code='' or kb_code is null then 0 when length(kb_code)>=2 and length(kb_code) <=3 then 1 else -1 end win,
  served_tag,
  cpm,
  ecpm,
  kb_sold_cpm
  
  
from 
(select a.placement_id
  , cb
  , "timestamp"
  , geo_country
  , estimated_timeout
  , ua_device_type
  , served_tag
  , case 
      when strpos(a.hdbd_json, a.served_tag) > 0 AND length(a.served_tag) > 1 then 'header tag' 
      when a.served_tag='h' then 'h' 
      when a.served_tag='' then 'blank' 
      when length(a.served_tag)=2 or length(a.served_tag)=3 then 'chain'
      else 'unknown'
    end served_type
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts') first_sent_bid_ts
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'bid_ts') second_sent_bid_ts
  , final_state
  , hdbd_time
  , hdbd_json
  , pbsbids
  , kb_code
  , kb_sold_cpm
  , cpm
  , c.ecpm

from aggregated_logs_5 a
inner join shahar_placement_estimated_timeout e on (a.placement_id=e.placement_id)
left join shahar_kbidder_chain_tag_ecpm_estimates c on (a.placement_id=c.placement_id and a.served_tag=c.tag_name)
where "timestamp" >= '2016-07-25'
) a

