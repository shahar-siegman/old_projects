select i."timestamp"
  , placement_id
  , client_ip
  , geo_country
  , cb
  , uid
  , jid
  , ua_device_type
  , ua_browser
  , ua_browser_ver
  , url
  , i.served_chain
  , i.served_tag
  , i.cpm
  , i.kb_sold_cpm
  , network,received_ssp_bid
  , rests
  , estimated_timeout
from impressions i
inner join sent_bids s using(placement_id, cb, client_ip)
where i."timestamp" between '2016-11-20 00:00' and '2016-11-20 00:30'
and placement_id in ('7895d426a704c60f43d29e95c61599d9','30f7da928a1e074a0b1c923734549d06','f15508bbb9b7c36f3b65c54fbcfc018d','25a94ecb6a0d4d1dea2ab5f335438d98')
