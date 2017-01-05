
select l.layoutid, date, an.code, an.type, an.kmn_floor, an.entity_type, 
	sum(kc.impressions) impressions, sum(kc.served) served, sum(kc.total_promised_income) promised, sum(kc.total_income) revenue
from kmn_kbidder_cpm kc
inner join kmn_layouts l on l.layoutid=kc.placementid
inner join kmn_ads_network an on an.layoutid=l.layoutid and an.id = kc.adtagid
where l.siteid='3981089c6367bb9381013a3c3f040cf9'
and date >='2016-12-10'
group by placementid, date, an.id
order by placementid, date, an.entity_Type, an.code

