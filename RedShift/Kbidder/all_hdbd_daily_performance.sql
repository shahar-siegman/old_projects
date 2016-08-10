
select r.tagid
	, l.name
    , l.floor_price
    , replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
	, r.date
	, r.impressions	
	, r.served
    , r.cost+r.profit revenue
    , h.hb_impressions_with_bids
    , h.hb_served

from kmn_tag_report r
inner join (
	select placement_id tagid
		, date(hour) date
        , sum(hb_served) hb_served
        , sum(hb_impressions_with_bids) hb_impressions_with_bids
	from kmn_header_bidding_data
    where hour >='2016-03-01'
    group by 1,2 ) h using(tagid,date)
inner join kmn_layouts l on l.layoutid=r.tagid
where date >='2016-03-01'
having hb_impressions_with_bids>0
