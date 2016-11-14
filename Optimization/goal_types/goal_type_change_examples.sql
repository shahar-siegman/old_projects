select l.layoutid
	, substring_index(s.sitename,'(',1) site
    , replace(substring_index(l.tag_url,'//',-1),'www.','') url
	, l.name
    , coalesce(elt(h.old_value,'A','B','C','A+','C+','G','G-','Kbidder','Max Fill Low FP','VH margin'),h.old_value) old
	, coalesce(elt(h.new_value,'A','B','C','A+','C+','G','G-','Kbidder','Max Fill Low FP','VH margin'),h.new_value) `new`
    , from_unixtime(h.timestamp) `when`
    , date(from_unixtime(h.timestamp)) time
    , r.cost+r.profit revenue
	, h.updated_by
    , ifnull(h.note,'') note
from kmn_history h
inner join kmn_layouts l on h.entity_id=l.layoutid
inner join kmn_Tag_report r on (r.tagid=l.layoutid and r.date='2016-10-31')
inner join kmn_sites s using(siteid)
where entity_type='placement'
and field='optimization_goal_id'
and l.placement_kind is null
and l.status='approved'
and h.timestamp>=unix_timestamp('2016-10-01')
and h.old_value !=''
and h.new_value !=''
order by h.timestamp desc