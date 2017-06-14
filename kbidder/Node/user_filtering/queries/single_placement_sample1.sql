select "timestamp", 
	placement_id, 
	uid, 
	kb_code, 
	kb_sold_cpm, 
	cpm, 
	pbsbids, 
	hdbd_json
from impressions i 
where length(hdbd_json)>0
and placement_id={placement_id}
and "timestamp" between {start_time} and {end_time}
and right(uid,2) in ({cookie_suffix})
limit 50