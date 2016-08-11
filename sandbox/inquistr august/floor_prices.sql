select plcmnts.tagid 
	, date(dt.dt) date_
    , substring_index(group_concat(floor order by timestamp desc),',',1) floor_price
from (select layoutid tagid from kmn_layouts where siteid='35a97f28bd5020da264fd9dcf23a49c4') plcmnts
join calendar dt on dt between '2016-06-01' and current_date()
left join kmn_floor_prices_history h 
    on h.date <= dt.dt
	and h.tagid=plcmnts.tagid
group by tagid, date_
order by tagid, date_;