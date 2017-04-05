create table shahar_cookie_performance_prediction
diststyle all sortkey (uid, placement_id) as
select "timestamp", placement_id, client_ip,uid, kb_code, pbsbids
from impressions i --on i.placement_id=s.placement_id and i.cb=s.cb and i.timestamp=s.timestamp
where JSON_ARRAY_LENGTH(pbsbids)>0
and timestamp between '2017-04-04 16:00' and '2017-04-04 16:10'
and placement_id in ('4a132f8f47f382d3bb09d44e628e0d19','ff84ddc3f6041825a7a9ff7641e572ac','2637deec99bf9be3d3a5ecdd9ca6255e')
and length(uid) >0
limit 1000;


http://redash.komoona.com/dashboard/kbidder-placement?p_placement_id=4a132f8f47f382d3bb09d44e628e0d19
http://redash.komoona.com/dashboard/kbidder-placement?p_placement_id=2637deec99bf9be3d3a5ecdd9ca6255e
