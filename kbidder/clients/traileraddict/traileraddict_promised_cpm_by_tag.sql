select placement_id
  , date_trunc('day',"timestamp") date_
  , served_tag
  , count(1) impressions
  , sum(cpm) sum_cpm
from impressions
where placement_id in ('5a1d2008609e0930ef4d443540aaf4cb',
'64a53d859603a95ce4ca979f1ab1c6bc',
'342bda538b0f9d8618404e222e0a730e',
'43d400179f0b10646a2417a9495d3652',
'8a727b186234d096e8ef8b7c1dd0e464',
'ffdf708d6f449c174924c4f091ff86e6',
'125ecec4be22c905096a02c7402f27d6')
and timestamp>='2016-09-19'
group by placement_id, date_, served_tag;

select
from impressions
where 
