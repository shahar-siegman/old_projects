
select 
	c.date
    , case
        when n.script like '%Komoona1%' then 'Komoona1'
		when n.script like '%Komoona2%' then 'Komoona2'
        when n.script like '%Komoona3%' then 'Komoona3'
        when n.script like '%32702%' then '32702'
        when n.script like '%51048%' then '51048'
        when n.script like '%116164%' then '116164'
	end as account
    , substring_index(l.tag_url,'//',-1) clean_url
    , round(n.kmn_floor*2.5,0)/2.5 floor_bin
	, sum(c.impressions) impressions
	, sum(c.served) served
    , sum(c.income) income
    , count(1) n_tags
from kmn_cpm c
inner join kmn_ads_network n on (c.ads_network_id = n.id)
inner join kmn_layouts l using (layoutid)
where c.timestamp between unix_timestamp('2016-03-01') and unix_timestamp('2016-06-25')
and c.type='pubmatic'
group by date, account, clean_url, floor_bin
;


select round(0.51,0)