select placement_id, "timestamp", pbsbids, hdbd_json
from temp_kb_placements_rows1
where placement_id in ('ea5a8a917eb53ab9df51a0691fcdbf') -- ('6c0d92acb681f83393cd4b5d6194dd05','ea5a8a917eb53ab9df51a0691fcdbf','ebde439cecfc9bca064b80d40f16c27c')
and timestamp>='2016-07-29'
and length(pbsbids)>5
limit 50;

select floor(first_sent_bid_ts::decimal(10,2)/100)*100 first_bid_ts
  , served_type
  , count(1)
from temp_kb_placements_rows1
where placement_id in ('5c312e17f768c831ac20170cd6386f8b','3fe0fd006d3c2a96533c0378ffba323f','3e5cb1662bb51da0795e48977826d427','ebde439cecfc9bca064b80d40f16c27c','6c0d92acb681f83393cd4b5d6194dd05','ea5a8a917eb53ab9df51a0691fcdbfd2')
and first_sent_bid_ts !=''
group by first_bid_ts, served_type;

select floor(first_sent_bid_ts::decimal(10,2)/100)*100 first_bid_ts
  , served_type
  , count(1)
from temp_kb_placements_rows1
where placement_id in ('5c312e17f768c831ac20170cd6386f8b','3fe0fd006d3c2a96533c0378ffba323f','3e5cb1662bb51da0795e48977826d427','ebde439cecfc9bca064b80d40f16c27c','6c0d92acb681f83393cd4b5d6194dd05','ea5a8a917eb53ab9df51a0691fcdbfd2')
and first_sent_bid_ts !=''
and timestamp >= '2016-07-31 14:00'
group by first_bid_ts, served_type;


;
select
  placement_id
  , date_trunc('hour',"timestamp") hour_
  , count(1) impressions
  , sum(case when length(pbsbids)>5 thyen 1 else 0 end) impressions_with_sent_bids
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 1300 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 1800 then 0 else 1 end) impressions_with_sent_bid_1800
from aggregated_logs_5
where 
  placement_id in ('5c312e17f768c831ac20170cd6386f8b', '3fe0fd006d3c2a96533c0378ffba323f', '3e5cb1662bb51da0795e48977826d427')
  -- ('0fdf1dfdd6555b461045aefec232050b','17e6f86dde3326893a73995be79bb46e','741aebc4a3619038194cb581247f19eb','8e95a19fc3718823e882d3fa9b89e88c')
group by placement_id, hour_;


select
  placement_id
  , case when length(pbsbids)>5 then least(floor( json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2)/100)*100,5000) 
 else 10000 end first_bid_ts
 , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1) network_
 , avg(case when length(hdbd_json)>5 and length(pbsbids)>5 and length(json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1),'rests'))>0
  then json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1),'rests')::decimal(8,2) else null end) avg_responder_response_delay
 , avg(case when length(hdbd_json)>5 and length(pbsbids)>5 and length(json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1),'cpm'))>0
  then json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1),'cpm')::decimal(8,2) else null end) avg_response_cpm
  , count(1) impressions
  , count(distinct uid) cookies
--  , sum(case when length(pbsbids)>5 and json_extract_path_text(json_extract_array_element_text(pbsbids,0),'sent_bid')::decimal(10,2)>0 then 1 else 0 end) impressions_with_sent_bids
from aggregated_logs_5
where 
  placement_id in ('5c312e17f768c831ac20170cd6386f8b', '3fe0fd006d3c2a96533c0378ffba323f', '3e5cb1662bb51da0795e48977826d427')
    --('0fdf1dfdd6555b461045aefec232050b','17e6f86dde3326893a73995be79bb46e','741aebc4a3619038194cb581247f19eb','8e95a19fc3718823e882d3fa9b89e88c')
  and timestamp >= '2016-07-30 07:00'
group by placement_id, first_bid_ts, network_;


select
  placement_id
  , case when length(pbsbids)>5 then least(floor( json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2)/100)*100,5000) 
 else 10000 end first_bid_ts
 , case when length(hdbd_json)>5 and length(pbsbids)>5 
  then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code') else null end first_responder_code
  , case when length(hdbd_json)>5 and length(pbsbids)>5 
  then left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1) else null end first_responder_network
  , case when length(hdbd_json)>5 and length(pbsbids)>5 
  then json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1)) else null end first_responder_json
  , case when length(hdbd_json)>5 and length(pbsbids)>5 and length(json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1),'rests'))>2
  then json_extract_path_text(hdbd_json,left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1),'rests')::decimal(8,2) else null end first_responder_rests

  , hdbd_json
  , pbsbids
--  , sum(case when length(pbsbids)>5 and json_extract_path_text(json_extract_array_element_text(pbsbids,0),'sent_bid')::decimal(10,2)>0 then 1 else 0 end) impressions_with_sent_bids
from aggregated_logs_5
where 
  placement_id in ('5c312e17f768c831ac20170cd6386f8b', '3fe0fd006d3c2a96533c0378ffba323f', '3e5cb1662bb51da0795e48977826d427')
  --('0fdf1dfdd6555b461045aefec232050b','17e6f86dde3326893a73995be79bb46e','741aebc4a3619038194cb581247f19eb','8e95a19fc3718823e882d3fa9b89e88c')
  and timestamp >= '2016-07-30 07:00'
  and length(pbsbids) >5
  order by uid, timestamp
limit 1000;


-- 5c312e17f768c831ac20170cd6386f8b, 3fe0fd006d3c2a96533c0378ffba323f, 3e5cb1662bb51da0795e48977826d427
select placement_id


  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 100 then 0 else 1 end) impressions_with_sent_bid_100
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 200 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 300 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 400 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 500 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 600 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 700 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 800 then 0 else 1 end) impressions_with_sent_bid_1300
  , sum(case when length(pbsbids)<5 or json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2) > 900 then 0 else 1 end) impressions_with_sent_bid_1800
;




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
 , served_tag
 , md5(url) url_md5
from aggregated_logs_5 A
where 
  placement_id in ('5c312e17f768c831ac20170cd6386f8b', '3fe0fd006d3c2a96533c0378ffba323f', '3e5cb1662bb51da0795e48977826d427')
    --('0fdf1dfdd6555b461045aefec232050b','17e6f86dde3326893a73995be79bb46e','741aebc4a3619038194cb581247f19eb','8e95a19fc3718823e882d3fa9b89e88c')
  and length(pbsbids)>5
  and length(uid) >5
  and timestamp >= '2016-07-25 07:00'
  and length(served_tag)>1
  and strpos(a.hdbd_json, a.served_tag) = 0
  order by uid, "timestamp", placement_id
 limit 1000;
 

insert into temp_kb_placements_rows1
select placement_id
  , cb
  , "timestamp"
  , case when final_state in ('tag', 'stat-1',  'placement', 'js-err') and length(hdbd_json)>4 then 1 else 0 end win
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

from aggregated_logs_5 a
where placement_id in   ('02616da2513ca0580908133fe4af88c7','6c71ef147b1282b8cda1226b5335a0c4','754088270109c65dab2efdfd27487121','8f5683cfba9109c0850c75e7baa7ccba','b6206ad037f9ff41bf6a2046aa1eca62','8fbbec6fdd52d002e67460fb3f2be516','f924845f67152f877e2a2304c5052f2b')
and timestamp >='2016-08-09 02:00:00';

