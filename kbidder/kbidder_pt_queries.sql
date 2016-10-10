select chain_name, startdate, an.code, ordinal, floor_price
from kmn_main_chain_history ch
inner join kmn_ads_network an on (an.id=ch.ad_network_id)
where an.layoutid='fea197961cf5984193fbe9a0a339e015';

select tagid, group_concat(code), c.date, max(c.impressions), sum(c.served), sum(c.income)
from kmn_cpm c
inner join kmn_ads_network an on (an.id=c.ads_network_id)
where tagid='fea197961cf5984193fbe9a0a339e015'
and an.code in ('p1','t5','t8','p2')
and c.timestamp between unix_timestamp('2016-09-16') and unix_timestamp('2016-09-23')
group by date
;

select entity_type, new_value, field, old_value, from_unixtime(timestamp) time_
from kmn_history where
entity_id='261cfaff734edf148027009277e278b5'
and entity_type='headerBiddingPlacementConfiguration'
and field='kbidder_configuration'
order by time_ desc;

select placement_id tagid
	, date
    , chain_codes
    , impressions
    , served 
from kmn_chain_report 
where placement_id='261cfaff734edf148027009277e278b5' 
and date >='2016-09-16' 
and chain_codes='p4:t1:z2:p5'
order by date, chain_codes
;

select date, an.id, code, find_in_set(code,'p1,t5,t6,p3') place, c.impressions kmn_cpm_imps, c.served kmn_cpm_served, a.impressions chain_imps, a.served chain_served, income, c.served/a.impressions fill_contrib
from kmn_cpm c
inner join kmn_ads_network an on (an.id=c.ads_network_id)
left join (select placement_id tagid, date, impressions, served from kmn_chain_report where placement_id='fea197961cf5984193fbe9a0a339e015' and date >='2016-09-16' and chain_codes  like 'p1:t5:t?:p?') a using(tagid,date)
where c.tagid='fea197961cf5984193fbe9a0a339e015'
and an.code in ('p1','t5','t6','p3')
and c.timestamp>=unix_timestamp('2016-09-16')
order by date, place;



select placement_id tagid, date,chain_codes, impressions, served from kmn_chain_report where placement_id='fea197961cf5984193fbe9a0a339e015' and date >='2016-09-16' 
order by date, chain_codes;



select date(hour) date_, placement_id, sum(no_bid_position_impressions), sum(no_bid_position_total_win_cpm), sum(no_bid_position_total_bid_cpm) 
from kmn_kbidder_data
where placement_id in ('0b2b1e012751fe245e12c4e8559f2384',
'1f4910d4c6598ced96834e2b8ed19e62',
'39a26bc7eb47383e1053c17c83222326',
'a21fc9eb47a677b9888cb6e0e2485ab5',
'f1942acbae21ba02349d8616070f5264',
'fea197961cf5984193fbe9a0a339e015')
and date(hour) >='2016-09-18'
group by date_, placement_id;


