select placement_id,
  count(1) auctions
    , sum(case when final_state in ('tag', 'stat-1',  'placement', 'js-err') and length(hdbd_json)>4 then 1 else 0 end) kb_wins
    , sum(case when final_state='placement' and strpos(a.hdbd_json, a.served_tag) > 0 AND length(a.served_tag) > 1 then 1 else 0 end) hb_tag_served
    , sum(case when final_state in ('tag', 'stat-1',  'placement', 'js-err') and length(hdbd_json)<=4 then 1 else 0 end) chain_attempts_no_hdbd
--  , sum(case final_state when 'tag' then 1 when 'stat-1' then 1 when 'placement' then 1 when 's-err' then 1 else 0 end) kb_wins
  , sum(case when final_state in ('tag', 'stat-1', 'js-err') and length(hdbd_json)>4 then 1 else 0 end) discrepancy
  , sum(case when final_state='placement' and strpos(a.hdbd_json, a.served_tag) <= 0 AND length(a.served_tag) > 1 then 1 else 0 end) chain_tag_served
  , sum(case when kb_sold_cpm>0 then 1 else 0 end) obligated_cost_count
  , sum(case when kb_sold_cpm>0 then kb_sold_cpm::decimal(6,2) else 0.00 end) obligated_cost_value
  , sum(case when cpm>0 then cpm::decimal(6,2) else 0 end) hdbd_revenue
 from temp_kbidder_rows a
 group by placement_id ;