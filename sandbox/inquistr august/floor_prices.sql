select plcmnts.tagid 
	, date(dt.dt) date_
    , substring_index(group_concat(floor order by timestamp desc),',',1) floor_price
from (select layoutid tagid from kmn_layouts where layoutid in ('65c5373395c62a79861cdbb584a60507' ,'9df0f201bbe9bb33297180784b8b276d')) plcmnts
join calendar dt on dt between '2016-07-01' and current_date()
left join kmn_floor_prices_history h 
    on h.date <= dt.dt
	and h.tagid=plcmnts.tagid
group by tagid, date_
order by tagid, date_;

insert into calendar (dt) values ('2016-08-15'),('2016-08-16'),('2016-08-17'),('2016-08-18'),('2016-08-19'),('2016-08-20'),('2016-08-21'),('2016-08-22')
