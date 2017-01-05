-- keep all the winners' times and bids
create table tmp_shahar_late_bid_aux1 
as
select impression_id,placement_id, "timestamp", client_ip, cb, reqts, rests, bid_ts, code, kb_sold_tag, sent_bid
from sent_bids
where "timestamp" between '2016-12-02' and '2016-12-07'
and kb_sold_tag=code
and bid_ts is not null
and sent_bid is not null
and length(kb_sold_tag)>1;


create table tmp_shahar_late_bid_aux2
as
select impression_id
  , placement_id
  , "timestamp"
  , client_ip
  , cb
  , sum(case when kb_sold_tag=code then received_ssp_bid else 0 end) used_ssp_bid
  , sum(case when kb_sold_tag=code then bid_ts else 0 end) sent_bid_ts
  , max(cpm) cpm
  , max(received_ssp_bid) greatest_bid
  , max(bid_ts) max_bid_ts
from sent_bids s
where "timestamp" between '2016-12-02' and '2016-12-07'
and length(kb_sold_tag)>0
and sent_bid is not null
group by impression_id, placement_id, "timestamp", client_ip, cb;

select date_trunc('day', "timestamp")::date as date_
  , placement_id
  , l.name
  , l.siteid
  , count(1) impressions_with_wins
  , sum(used_ssp_bid) used_bid_value
  , sum(cpm) revenue
  , sum(case when cpm=0 then 0 else 1 end) impressions_with_served
  , sum(case when cpm>0 and greatest_bid - used_ssp_bid > 0.05 then 1 else 0 end) impressions_with_late_bid_value
  , sum(case when cpm>0 then greatest_bid - used_ssp_bid else 0 end) late_bid_value
  , avg(case when cpm>0 and greatest_bid - used_ssp_bid > 0.05 then max_bid_ts-sent_bid_ts else null end) avg_late_bid_time
from tmp_shahar_late_bid_aux2 au
left join kmn_layouts l on l.layoutid=au.placement_id
 group by date_, placement_id, l.name, l.siteid
