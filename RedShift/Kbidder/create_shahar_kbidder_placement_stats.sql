create table if not exists shahar_kbidder_placement_stats
(placement_id char(32),
date date,
latest_entry datetime,
auctions int(11),
kb_wins int(11),
hb_tag_served int(11),
chain_attempts_no_hdbd int(11),
discrepancy int(11),
chain_tag_served int(11),
obligate_cost_count int(11),
obligated_cost_value decimal(10,4),
hdbd_revenue decimal(10,4),
estimated_adtag_revenue decimal(10,4),
primary key (placement_id, date));