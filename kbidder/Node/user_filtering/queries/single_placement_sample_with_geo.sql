select "timestamp", 
	placement_id, 
	case geo_country when 'US' then 'US' else 'Other' end is_geo_us,
	uid, 
	kb_code, 
	kb_sold_cpm, 
	cpm, 
	hdbd_json
from shahar_placement_user_sample1
where placement_id = {placement_id} and geo_country {not} in ('US')

