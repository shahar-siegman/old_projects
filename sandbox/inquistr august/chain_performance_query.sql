-- 'Billboard.com';
-- '19825960852f114eccbdaa18a0f02505,38ece84d79878b30ca01029bee5d0220,3aad7a7e4233fe8199fccb0320e2d33f,413d7d5b881d72a9fd4523854acfed81,88b92085a8bed9fafaa466e069662774,99db2396976f7c3ae91ce1effc2f4d8e,ab1eaf415e09e697d2b1b29d95030c20,df297f89097518c74a002a2f5afd0d91,ee14eadb4cfa28521b1492935c80e42c,f74a2780c46f4559298e0dc8d5ab3bc3';
-- mangapark.me  
-- '0be18176ed0056a23ebef5c24069a180,2fcca985cf38bd96f9749cc2fa1d4f9b,534550607cbfd5d133bcb90698473da7,6452f3a321d905420f8d29f08e0f6194,9e98f65cb772133c88363e5563f7b9ab,d9738e84c72d9c6ea5b8d35d7fb41163,da83a7a04401c64417cf439d7fea4e94,e87bb757749d85a91bbbbe23abc1186e,f068813b52cdea3cfabc35914054eef8,f1c0a55e87404c385824616bc6b917da';
-- mangareader.net;
-- '07b62f6bcd7f0cae0a9d6c09541e3b2e,1d0ec77380cc678bb106b74caec1cb41,22d36484831bf01d9c8507ccb8e22e23,684cfc9d47d347492851d57b8479d282,70179a8d9ecdb3b1a170d26689a62ece,71e51937d048d6ebf3248c416092b961,7a76074b935d79400584174ff282fe6c,86e7a4db989d08a949391cacdc3b46e0,999e2ac22723ae740381dbf9bf75c050,a8e0425c713297971d87788c685f854d,aacf932acc2eb7f4208971aa84d93417,ade22c3333abaca29c0cfbd46ae68730,b1a2a05e0a61a87c99911239f30adb0a,e44e20c0c975374c526a3d9892f603e9,e52db07c1903af919dc1ef0a5794d0de,ef20a728a73fc4afac92572b58ec5d1f,f8fc78a49cf71c734075c4cdc1e1bb37';
-- bestallergysites
-- '78b2cd88714813d7c0a7e24e587121d8,2313019533b85ad1bf527fa60a3121c0,2a87a2c6af6c19940c6652154f84fb18,27804daaa547bb42d57ddda303d8e9f0,8d635aaa407fc8010bbed39483563203,4a21b52d03ea836c7b268d29945bf2aa,f387f6db1ef198e1381b92be9c5cc3bd,b41c5a90fbf4d4d7e5e004213e61409a,f28ff435d263c6dab1ba316575a8471c,e0c5a2d64c07b59fc3645029c60d2b2e,95939f2d685e094b9ad2cc680d1c21af'
-- **** set parameters ***
set @start_date = '2016-10-20';
set @placement_list = '78b2cd88714813d7c0a7e24e587121d8,2313019533b85ad1bf527fa60a3121c0,2a87a2c6af6c19940c6652154f84fb18,27804daaa547bb42d57ddda303d8e9f0,8d635aaa407fc8010bbed39483563203,4a21b52d03ea836c7b268d29945bf2aa,f387f6db1ef198e1381b92be9c5cc3bd,b41c5a90fbf4d4d7e5e004213e61409a,f28ff435d263c6dab1ba316575a8471c,e0c5a2d64c07b59fc3645029c60d2b2e,95939f2d685e094b9ad2cc680d1c21af';

-- **** verify parameters ***
select max(dt) from calendar;
select @placement_list;
select @start_date;

-- **** push new dates into calendar ***
insert into calendar (dt) values ('2016-10-31');, ('2016-10-29'), ('2016-10-30'), ('2016-11-01'), ('2016-11-02'), ('2016-11-03');
commit;
-- **** chain performance query ***
select 'bestallergysites' subject 
    , cr.placement_id
  	, cr.chain_codes
    , cr.date
    , cr.impressions impressions
    , cr.served
    , cr.house
    , find_in_set(a.code,replace(cr.chain_codes,':',',')) place
    , a.code tag_code
    , a.entity_type
  	, a.tag_impressions
    , a.served tag_served
    , round(1000*a.income/a.served,2) tag_ecpm
    , a.served/cr.impressions tag_fill_contrib
    , 1000*a.income/cr.impressions tag_rcpm_contrib
from kmn_chain_report cr
left join (
	select c.tagid placement_id, ad.code,c.date,c.impressions tag_impressions, c.served,c.income, ad.entity_type
    from kmn_cpm c force index(idx_timestamp)
    inner join kmn_ads_network ad on (c.ads_network_id=ad.id)
    where find_in_set(tagid,@placement_list)>0 
    and c.timestamp >= unix_timestamp(@start_date)
    ) a on 
		  cr.placement_id = a.placement_id 
		    and concat(':',chain_codes,':') like concat('%:',a.code,':%') 
        and a.date=cr.date
where 
	find_in_set(cr.placement_id,@placement_list)>0
  and cr.date >=@start_date
 order by placement_id, cr.date, impressions desc, place;
 

-- **** placement floor price query ***
select plcmnts.tagid 
	, date(dt.dt) date_
    , substring_index(group_concat(floor order by timestamp desc),',',1) floor_price
from (select layoutid tagid from kmn_layouts where find_in_set(layoutid,@placement_list)>0) plcmnts
join calendar dt on dt between @start_date and current_date()
left join kmn_floor_prices_history h 
    on h.date <= dt.dt
	and h.tagid=plcmnts.tagid
group by tagid, date_
order by tagid, date_;






    


