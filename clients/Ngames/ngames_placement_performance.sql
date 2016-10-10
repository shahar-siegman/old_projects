select tagid
	, date
	, l.name
    , l.name like '%mobile' is_mobile
    , replace(l.tag_url, 'http://','') url
    , concat(l.ad_width,'x',l.ad_height) size
    , impressions
    , served
    , (cost+profit) revenue
    , profit
from kmn_tag_report r
inner join kmn_layouts l on (l.layoutid=r.tagid)
where l.siteid='bd6319c426df5fe1f9aa7b5cace9be38'
and name not like '%[deleted]'
and date >='2016-08-01';


select entity_id placement_id,updated_by, note, new_value, old_value, from_unixtime(timestamp) time_
from kmn_history h
where h.entity_type='placement'
and h.entity_id in ('123321b0ecce594df3069dff9498598a',
'1e7d4d6cc0252d496c9bd3af80db63ed',
'29fb5b72175a9429f17c7ff36e64568b',
'2edfe14540b51a047dc8f66c219c7804',
'3168055598cf9414d239ae592b30bc5a',
'33a4b2425c65936d79ab7df33f05ef8b',
'3eae1d16089db3190a280dd2188ada77',
'4b04804bad88916ba26f4cf747b98a14',
'7a04c0dfa4f4871328de1dd741595012',
'9de9415d2b34d93155f1938250a1885e',
'a09bac17d8c88cfea2bfba45d58ef0d4',
'c043332fa954814a8a5b88539d84ffc7',
'd019d0054972a65f86dd4bff5300066a',
'e664d057e00d2e7e52da4e25e8bda1a4',
'f070fc46b5a4db18c8e936c2ee93e6ca')
and field='optimization_goal_id'
and timestamp>unix_timestamp('2016-08-01')
order by date(time_),entity_id
