select placement_id
  , cb
  , "timestamp"
  , final_state
  , hdbd_time
  , hdbd_json
  , kb_code
  , kb_sold_cpm
  , pbsbids
  , accepted_sent_bid
  , case accepted_sent_bid when 1 then first_sent_bid_ts when 2 then second_sent_bid_ts else '' end accepted_bid_ts
  , case accepted_sent_bid when 1 then second_sent_bid_ts when 2 then third_sent_bid_ts else '' end rejected_bid_ts
from (
  select placement_id
    , cb
    , "timestamp"
    , final_state
    , hdbd_time
    , hdbd_json
    , kb_code
    , kb_sold_cpm
    , pbsbids
    , case when kb_code=first_sent_bid_code and first_sent_bid_code!=second_sent_bid_code and length(second_sent_bid_code)>0 then 1
        when kb_code=second_sent_bid_code and first_sent_bid_code!=second_sent_bid_code and length(second_sent_bid_code)>0 then 2
        else 0 end accepted_sent_bid
    , first_sent_bid_ts 
    , second_sent_bid_ts 
    , third_sent_bid_ts
  from (
    select placement_id
      , cb
      , "timestamp"
      , final_state
      , hdbd_time
      , hdbd_json
      , kb_code
      , kb_sold_cpm
      , pbsbids
      , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code') first_sent_bid_code
      , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'code') second_sent_bid_code
      , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts') first_sent_bid_ts
      , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'bid_ts') second_sent_bid_ts
      , json_extract_path_text(json_extract_array_element_text(pbsbids, 2),'bid_ts') third_sent_bid_ts
    from aggregated_logs_5
    where placement_id='83d6f1934c618a6b7f30f17f1671d794'
    and date_trunc('day',timestamp)::date='2016-07-24'
    and length(kb_code)>0 
    ) a
  where (kb_code=first_sent_bid_code and first_sent_bid_code!=second_sent_bid_code and length(second_sent_bid_code)>0) or
  (kb_code=second_sent_bid_code and first_sent_bid_code!=second_sent_bid_code and length(second_sent_bid_code)>0)
) b
where accepted_sent_bid >0 
and (accepted_sent_bid=1 and length(second_sent_bid_ts)>0 or accepted_sent_bid=2 and length(third_sent_bid_ts)>0)

