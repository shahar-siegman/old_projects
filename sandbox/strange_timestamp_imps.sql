select placement_id, "timestamp", timestamp_kbstart, timestamp_kbdata, timestamp_kbend, timestamp_tag, timestamp_placement, cb, s_server, events_count, served_chain, adtag_ts_list, hdbd_json, pbsbids, kb_code, kb_sold_cpm
from impressions
where placement_id in ('7895d426a704c60f43d29e95c61599d9','30f7da928a1e074a0b1c923734549d06','f15508bbb9b7c36f3b65c54fbcfc018d','25a94ecb6a0d4d1dea2ab5f335438d98')
and "timestamp" in ('2016-12-04 16:44:03', '2016-12-04 16:33:09 ') 
and (length(served_chain) >0 or length(kb_sold_cpm)>0)
limit 500;