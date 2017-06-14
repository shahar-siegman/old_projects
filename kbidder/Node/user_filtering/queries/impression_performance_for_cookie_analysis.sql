select "timestamp", placement_id, client_ip, uid, kb_code, kb_sold_cpm, cpm, rb_impression, pbsbids, hdbd_json, pc
from impressions i 
where length(hdbd_json)>0
and placement_id in ('e5deb75140b5cfbbb0f3581a054ae7cf', '794b998efb72b374ef36dcffeadd4b3f', '2f85eff0ca3e85a84473681c0e113cbe') -- ('4a132f8f47f382d3bb09d44e628e0d19','ff84ddc3f6041825a7a9ff7641e572ac','2637deec99bf9be3d3a5ecdd9ca6255e')
and right(uid,3) in ('0aa','0c0','0de','044', '010')
--('0aa','0c0','0de','044', '010', '02b', '03a','022')

