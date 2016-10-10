 select date_
	, opt_type
    , sum(impressions)
    , sum(served)
    , sum(revenue)
 from (
 select r.tagid placement_id
	, r.date date_
	, substring_index(group_concat(h.new_value order by h.timestamp desc),',',1) opt_type
    , from_unixtime(max(h.timestamp)) last_change_date
    , r.impressions
    , r.served
    , (r.cost+r.profit) revenue
from kmn_tag_report r
left join kmn_history h on 
	(r.tagid=h.entity_id 
    and r.date>=date(from_unixtime(h.timestamp))
    and entity_type='placement'
    and field ='optimization')
where r.tagid in (select distinct tagid from kmn_tag_report where date>'2016-07-01' and r.cost>1 )
and r.date >='2016-07-01'
#(select layoutid from kmn_layouts where siteid='0e2acd7554ddc41598b322b27c3d6ab0')
group by placement_id, date_
) b group by date_, opt_type;