select r.tagid
	, r.date
    , r.impressions
    , r.served
    , r.cost+r.profit revenue
	, coalesce(a.opt_code, l.optimization) opt_code
    , case coalesce(a.opt_code, l.optimization)
		when 3 then 'maestro'
        when 4 then 'maestro'
        when 5 then 'maestro'
        when 6 then 'kbidder'
        when 100 then 'SCO'
        when 101 then 'SCO-D'
        when 102 then 'SCO-R'
	end opt_type
from kmn_tag_report r
inner join kmn_layouts l on (l.layoutid=r.tagid)
left join (
	select h1.entity_id placement_id
			, coalesce(date(from_unixtime(max(h0.timestamp))),'2016-06-30') date0
			, date(from_unixtime(h1.timestamp)) date1
			, substring_index(group_concat(h1.old_value order by h1.timestamp),',',1) opt_code
	from kmn_history h1 
	left join kmn_history h0 on 
		(h1.entity_id=h0.entity_id 
		and h0.entity_type='placement'
		and h0.field ='optimization'
		and date(from_unixtime(h0.timestamp))>='2016-07-01' 
		and date(from_unixtime(h0.timestamp)) < date(from_unixtime(h1.timestamp))
		)
	where 1=1
	and h1.entity_type='placement'
	and h1.field ='optimization'
	and h1.timestamp>= unix_timestamp('2016-07-01')
	group by placement_id, date1
    having opt_code != ''
) a on (r.tagid=a.placement_id and r.date >= a.date0 and r.date < a.date1)
where r.date>='2016-07-01'
and r.date <= '2016-08-22'
and (r.cost+r.profit) > 0.5

