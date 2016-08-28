-- create table temp_kb_placements_rows1 as 
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
where placement_id in ('83d6f1934c618a6b7f30f17f1671d794'
  , '3e5cb1662bb51da0795e48977826d427'
  , '6c0d92acb681f83393cd4b5d6194dd05'
  , 'ebde439cecfc9bca064b80d40f16c27c'
  , '5c312e17f768c831ac20170cd6386f8b'
  , '3fe0fd006d3c2a96533c0378ffba323f'
  , '741aebc4a3619038194cb581247f19eb')
and timestamp >= '2016-07-28'
limit 100;
