select *
from impressions i
inner join shahar_placement_lists l on (l.placement_id=i.uid)
where l.list_id=7;