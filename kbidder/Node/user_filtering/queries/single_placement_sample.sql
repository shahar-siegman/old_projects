insert into shahar_placement_user_sample1
select "timestamp", 
	placement_id, 
	client_ip,
	geo_country,
	uid, 
	kb_code, 
	kb_sold_cpm, 
	cpm, 
	rb_impression, 
	pbsbids, 
	hdbd_json, 
	pc,
	filtered,
	filter_reason,
	flm
from impressions i 
where length(hdbd_json)>0
and placement_id={placement_id}
and "timestamp" between {start_time} and {end_time}
and right(uid,2) in ({cookie_suffix})