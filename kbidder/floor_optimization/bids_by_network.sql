select i.placement_id, l.name, s.network, regexp_substr(l.name, '[0-9]+x[0-9]+') ad_size, i.uid, i."timestamp", i.cb, s.received_ssp_bid
from impressions i
inner join sent_bids s on s.placement_id = i.placement_id and s.timestamp=i.timestamp and i.cb=s.cb
inner join kmn_layouts l on s.placement_id =l.layoutid
  where l.siteid='3981089c6367bb9381013a3c3f040cf9' 
  and l.placement_kind='kbidder'
  and (i."timestamp" between '2017-02-06 19:10' and '2017-02-06 19:25' OR
  i."timestamp" between '2017-01-25 19:10' and '2017-01-25 19:25')
  and length(uid)>2
  and received_ssp_bid>0
order by placement_id, network, uid, i."timestamp" 
