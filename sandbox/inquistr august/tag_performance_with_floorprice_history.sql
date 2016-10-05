
select ads_network_id
	, a.date
    , if(isnull(mch_latest),ch_floor_price,if(isnull(ch_latest),mch_floor_price,if(mch_latest>ch_latest,mch_floor_price,ch_floor_price))) tag_floor_price
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
	from (
		select cp.ads_network_id
			, cp.date 
            , cp.timestamp
            , cp.served
            , cp.impressions
            , cp.income
		from kmn_cpm cp force index (idx_timestamp)
		where find_in_set(tagid,@placement_list)>0 
			and timestamp between unix_timestamp(@start_date) and unix_timestamp(current_date()) ) tags_dates
	left join kmn_chain_history ch on (ch.ad_network_id=tags_dates.ads_network_id and tags_dates.date >= date(ch.startdate))
	left join kmn_main_chain_history mch on (mch.ad_network_id=tags_dates.ads_network_id and tags_dates.date >= date(mch.startdate))
	group by tags_dates.ads_network_id, tags_dates.date ) a

;


select @placement_list;
set @start_date = '2016-09-25';
select @start_date
