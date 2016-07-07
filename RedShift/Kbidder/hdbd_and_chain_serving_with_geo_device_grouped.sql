select placement_id
  , case when country not in ('US','CA','UK','IT','FR','ES','NL','PL','DE','AU','JP','IN','BR','MX','IL','NZ','NO','FI','IE','PT','AT','SE',
      'DK','AR','EG','TH','ID','RU','VN','PE','CO','BE','ZA','CL','UA','VE','EC') then 'Other' ELSE country end country_
  , device
  , case when j_bid='' then null else least(round(j_bid::real*2.5)/2.5,10.0) end j_bid_bin
  , case when l_bid='' then null else least(round(l_bid::real*2.5)/2.5,10.0) end l_bid_bin
  , case when o_bid='' then null else least(round(o_bid::real*2.5)/2.5,10.0) end o_bid_bin
  , case when p_bid='' then null else least(round(p_bid::real*2.5)/2.5,10.0) end p_bid_bin
  , case when s_bid='' then null else least(round(s_bid::real*2.5)/2.5,10.0) end s_bid_bin
  , count(impression_served) impressions
  , sum(impression_served) served
  , sum(case when hdbd_network_served in ('j','l','o','p','s') then 1 else 0 end) hdbd_served
  , round(sum(nrows)/count(impression_served),2) avg_nrows
 
 from (
  select a.placement_id
      , date_trunc('hour',a."timestamp") timestamp_
      , a.cb
      , max(a.geo_country) country
      , max(a.ua_device_type) device
      , max(json_extract_path_text(a.hdbd_json, 'j','cpm')) j_bid
      , max(json_extract_path_text(a.hdbd_json, 'l','cpm')) l_bid
      , max(json_extract_path_text(a.hdbd_json, 'o','cpm')) o_bid
      , max(json_extract_path_text(a.hdbd_json, 'p','cpm')) p_bid
      , max(json_extract_path_text(a.hdbd_json, 'S','cpm')) s_bid
      , max(case 
        when served_tag!='' and  served_tag= json_extract_path_text(a.hdbd_json, 'j','code') then 'j'
        when served_tag!='' and  served_tag= json_extract_path_text(a.hdbd_json, 'l','code') then 'l'
        when served_tag!='' and  served_tag= json_extract_path_text(a.hdbd_json, 'o','code') then 'o'
        when served_tag!='' and  served_tag= json_extract_path_text(a.hdbd_json, 'p','code') then 'p'
        when served_tag!='' and  served_tag= json_extract_path_text(a.hdbd_json, 'S','code') then 'S'
       else null end) hdbd_network_served
      , max(case when served_tag_network='h' then 0 else 1 end) impression_served
      , max(case 
        when timestamp_placement is not null then 'placement' 
        when final_state='hb_pl' then 'a.hb_pl' 
        when final_state='js-err' then 'e.js-err' 
        when final_state='tag' then 'b.tag' 
        when final_state='stat-1' then 'd.stat-1'  
        else final_state end
          ) final_state_
      , count(1) nrows
    from aggregated_logs_5 a
    inner join shahar_placement_lists l using(placement_id)
--    left join hdbd_networks net on json_extract_path_text(a.hdbd_json, net.network_letter,'cpm') != ''
    where "timestamp" between '2016-06-25 12:00:00' and '2016-06-26 00:00:00'
    and list_id=5
  group by a.placement_id, timestamp_, a.cb
  ) q
where final_state_ in ('e.js-err','placement')
group by q.placement_id, country_, q.device, j_bid_bin, l_bid_bin, o_bid_bin, p_bid_bin, s_bid_bin;

