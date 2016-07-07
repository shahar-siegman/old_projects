select * from (
  select a.placement_id
      , a.cb
      , a.geo_country
      , a.ua_device_type
      , net.network_letter
      , date_trunc(a."timestamp",'hour') timestamp_
      , count(1) nrows
      , max(json_extract_path_text(a.hdbd_json, net.network_letter,'cpm')) bid
      , max(case when served_tag_network='h' then '0' else served_tag_network end) served_network
      , max(case when served_tag= json_extract_path_text(a.hdbd_json, net.network_letter,'code') then 1 else 0 end) hdbd_served
      , max(case 
        when timestamp_placement is not null then 'placement' 
        when final_state='hb_pl' then 'a.hb_pl' 
        when final_state='js-err' then 'e.js-err' 
        when final_state='tag' then 'b.tag' 
        when final_state='stat-1' then 'd.stat-1'  
        else final_state end
          ) final_state_
    from aggregated_logs_5 a
    inner join shahar_placement_lists l using(placement_id)
    left join hdbd_networks net on json_extract_path_text(a.hdbd_json, net.network_letter,'cpm') != ''
    "timestamp" between '2016-06-24 20:00:00' and '2016-06-25 01:00:00'
  group by a.placement_id, a.cb, a.geo_country, a.ua_device_type, net.network_letter, timestamp_
  ) q
where final_state_ in ('e.js-err','placement');
  
