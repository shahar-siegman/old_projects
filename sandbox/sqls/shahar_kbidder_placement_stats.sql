select * from kmn_header_bidding_placement
where placement_id='83d6f1934c618a6b7f30f17f1671d794';

select *
from kmn_header_bidding
where header_bidding_id='c940cdd5d7044f46aae4ad946546e5c5';

select * from kmn_header_bidding_serving_trees t where t.placement_id='83d6f1934c618a6b7f30f17f1671d794'
;



create table if not exists shahar_kbidder_placement_stats
(placement_id char(32),
time datetime,
latest_entry datetime,
auctions int(11),
kb_wins int(11),
hb_tag_served int(11),
chain_attempts_no_hdbd int(11),
discrepancy int(11),
chain_tag_served int(11),
obligated_cost_count int(11),
obligated_cost_value decimal(10,4),
hdbd_revenue decimal(10,4),
estimated_adtag_revenue decimal(10,4),
primary key (placement_id, time));

