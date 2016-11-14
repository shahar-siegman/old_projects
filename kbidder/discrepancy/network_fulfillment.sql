

select kcpm.placementid, kcpm.date, an.type,an.code, sum(kcpm.total_promised_income) promised_income, avg(cpm.income) actual_income
from kmn_kbidder_cpm kcpm
inner join kmn_ads_network an on (an.id=kcpm.adtagid)
inner join kmn_cpm cpm on (cpm.ads_network_id=kcpm.adtagid and cpm.timestamp between unix_timestamp(kcpm.date) and unix_timestamp(kcpm.date)+3600*24-1) 
where placementid in ('25a94ecb6a0d4d1dea2ab5f335438d98','30f7da928a1e074a0b1c923734549d06','7895d426a704c60f43d29e95c61599d9','f15508bbb9b7c36f3b65c54fbcfc018d')
and kcpm.date>='2016-10-27'
and cpm.timestamp > unix_timestamp('2016-10-27')
group by placementid, kcpm.date, an.type, an.code
;
select layoutid, name
from kmn_layouts
where name like 'fark%'
and placement_kind='kbidder'