select tagid
	, date
	, lower(code) code
	, c.type network
	,  sum(income) revenue
from kmn_cpm c force index (idx_timestamp)
left join shahar_network_code nc on nc.network=c.type
where c.tagid in (select layoutid from kmn_layouts l where l.placement_kind='kbidder')
and c.timestamp>= unix_timestamp(current_date)-7*3600*24
group by tagid, date, code
