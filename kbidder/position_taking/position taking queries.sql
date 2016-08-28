select placement_id
  , case when sent_bid> 0.1 and  sent_bid > greatest(aol_bid,pubmatic_bid,openx_bid) then 'yes' else 'no' end sent_higher_bid_than_received
  , case when  greatest(aol_bid,pubmatic_bid,openx_bid) =0 then  'no' else 'yes' end has_any_network_bid
  , case when  greatest(aol_bid,pubmatic_bid,openx_bid) < 0.2 then  'no' else 'yes' end has_any_network_significant_bid
  , case when length(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')) >1 
      and json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')='kmn'
      then 'yes'
      else 'no'
      end bid_source_komoona
  , count(placement_id) cnt
  , sum(case when length(served_tag)>1 then 1 else 0 end) served
from (
select
  placement_id
  , case when length(json_extract_path_text(a.hdbd_json,'o','cpm'))>0 then json_extract_path_text(a.hdbd_json,'o','cpm')::decimal(6,2) else 0 end aol_bid
  , case when length(json_extract_path_text(a.hdbd_json,'p','cpm'))>0 then json_extract_path_text(a.hdbd_json,'p','cpm')::decimal(6,2) else 0 end pubmatic_bid
  , case when length(json_extract_path_text(a.hdbd_json,'e','cpm'))>0 then json_extract_path_text(a.hdbd_json,'e','cpm')::decimal(6,2) else 0 end openx_bid
  , case when length(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')) >1 
      then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')::decimal(6,2) 
      else 0 
      end sent_bid
  , pbsbids
  , served_tag
from aggregated_logs_5 a
where placement_id in ('02616da2513ca0580908133fe4af88c7','3fe0fd006d3c2a96533c0378ffba323f')
and timestamp >= '2016-08-10'
and timestamp <= '2016-08-16'
) a
group by placement_id, sent_higher_bid_than_received, has_any_network_bid, has_any_network_significant_bid, bid_source_komoona;

---------------------------------------------------------------------------
select * from (
select
  case when length(json_extract_path_text(a.hdbd_json,'o','cpm'))>0 then json_extract_path_text(a.hdbd_json,'o','cpm')::decimal(6,2) else 0 end aol_bid
  , case when length(json_extract_path_text(a.hdbd_json,'p','cpm'))>0 then json_extract_path_text(a.hdbd_json,'p','cpm')::decimal(6,2) else 0 end pubmatic_bid
  , case when length(json_extract_path_text(a.hdbd_json,'e','cpm'))>0 then json_extract_path_text(a.hdbd_json,'e','cpm')::decimal(6,2) else 0 end openx_bid
  , case when length(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')) >1 
      then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')::decimal(6,2) 
      else 0 
      end sent_bid
 , case when length(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')) >1 
      and json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')='kmn'
      then 1
      else 0
      end bid_source_komoona

  , served_tag
  , pbsbids
  , hdbd_json
from aggregated_logs_5 a
where placement_id in ('02616da2513ca0580908133fe4af88c7','3fe0fd006d3c2a96533c0378ffba323f')
and timestamp >= '2016-08-10'
and timestamp <= '2016-08-14' ) b
where  greatest(aol_bid,pubmatic_bid,openx_bid) < sent_bid;

 ------------------------------------------------------------------
select placement_id
  , "timestamp"
  , date_trunc('day',"timestamp") "date"
  , case when length(json_extract_path_text(hdbd_json,'o','bid_ts'))>0 and json_extract_path_text(hdbd_json,'o','bid_ts')::decimal(10,2) < 2500 then aol_bid else 0 end aol_bid
  , case when length(json_extract_path_text(hdbd_json,'p','bid_ts'))>0 and json_extract_path_text(hdbd_json,'p','bid_ts')::decimal(10,2) < 2500 then pubmatic_bid else 0 end pubmatic_bid
  , case when length(json_extract_path_text(hdbd_json,'e','bid_ts'))>0 and json_extract_path_text(hdbd_json,'e','bid_ts')::decimal(10,2) < 2500 then openx_bid else 0 end openx_bid
  , pubmatic_bid
  , openx_bid
  , sent_bid
  , pbsbids
  , served_tag
from (
select
  placement_id
  , "timestamp"
  , case when regexp_instr(json_extract_path_text(hdbd_json,'o','cpm'),'^[0-9|\.]+$')>0 then json_extract_path_text(hdbd_json,'o','cpm')::decimal(6,2) else 0 end aol_bid
  , case when regexp_instr(json_extract_path_text(hdbd_json,'p','cpm'),'^[0-9|\.]+$')>0 then json_extract_path_text(hdbd_json,'p','cpm')::decimal(6,2) else 0 end pubmatic_bid
  , case when regexp_instr(json_extract_path_text(hdbd_json,'e','cpm'),'^[0-9|\.]+$')>0 then json_extract_path_text(hdbd_json,'e','cpm')::decimal(6,2) else 0 end openx_bid
  , case when regexp_instr(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid'),'^[0-9|\.]+$') >0 
      then json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid')::decimal(6,2) 
      else 0 
      end sent_bid
  , pbsbids
  , hdbd_json
  , served_chain
  , served_tag
from aggregated_logs_5 a
where placement_id in ('02616da2513ca0580908133fe4af88c7','3fe0fd006d3c2a96533c0378ffba323f')
and timestamp >= '2016-08-10'
and timestamp <= '2016-08-16'
) a
where sent_bid> 0.1 and  sent_bid > greatest(aol_bid,pubmatic_bid,openx_bid) and
  length(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')) >1 
      and json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_src')='kmn' --  bid_source_komoona
;
------------------------------------------------------------------------------------;
select case when (regexp_instr('1','^[0-9|\.]+$') > 0) then 'a' else 'b' end
