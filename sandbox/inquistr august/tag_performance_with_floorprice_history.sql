
select ads_network_id
	, a.date
    , if(isnull(mch_latest),ch_floor_price,if(isnull(ch_latest),mch_floor_price,if(mch_latest>ch_latest,mch_floor_price,ch_floor_price))) tag_floor_price
    , type
    , impressions
    , served
    , income
from (
	select tags_dates.ads_network_id
		, tags_dates.date
		, substring_index(group_concat(ch.floor_price order by ch.startdate desc),',',1) ch_floor_price 
		, max(ch.startdate) ch_latest
		, substring_index(group_concat(mch.floor_price order by mch.startdate desc),',',1) mch_floor_price 
		, max(mch.startdate) mch_latest
        , tags_dates.served
        , tags_dates.impressions
        , tags_dates.income
        , tags_dates.type
	from (
		select cp.ads_network_id
			, cp.date 
            , cp.timestamp
            , cp.served
            , cp.impressions
            , cp.income
            , cp.type
		from kmn_cpm cp force index (idx_timestamp)
		where find_in_set(tagid,@placement_list)>0 
			and timestamp between unix_timestamp(@start_date) and unix_timestamp(current_date()) ) tags_dates
	left join kmn_chain_history ch on (ch.ad_network_id=tags_dates.ads_network_id and tags_dates.date >= date(ch.startdate))
	left join kmn_main_chain_history mch on (mch.ad_network_id=tags_dates.ads_network_id and tags_dates.date >= date(mch.startdate))
	group by tags_dates.ads_network_id, tags_dates.date ) a

;


select @placement_list;
set @start_date = '2016-09-15';
select @start_date;

set @placement_list='0be18176ed0056a23ebef5c24069a180,2fcca985cf38bd96f9749cc2fa1d4f9b,534550607cbfd5d133bcb90698473da7,6452f3a321d905420f8d29f08e0f6194,9e98f65cb772133c88363e5563f7b9ab,d9738e84c72d9c6ea5b8d35d7fb41163,da83a7a04401c64417cf439d7fea4e94,e87bb757749d85a91bbbbe23abc1186e,f068813b52cdea3cfabc35914054eef8,f1c0a55e87404c385824616bc6b917da';
