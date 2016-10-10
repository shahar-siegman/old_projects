select s.sitename
	, l.tag_url
    , l.name
    , l.layoutid
    , if(l.name like '%mobile%',1,0) is_mobile
    , hbp.enable_position_taking is_position_taking
    , date(kd.hour) date_
    , sum(kd.impressions) kd_impressions
    , max(r.impressions) r_impressions
    , sum(kd.impressions_with_bids) imps_with_bids
    , sum(kd.impressions_with_wins) imps_with_wins
	, max(r.served) served
    , sum(kd.no_bid_position_impressions) no_bid_pt_imps
    , sum(kd.no_bid_position_impressions_with_wins) no_bid_pt_wins
    , sum(kd.no_bid_position_total_win_value) pt_no_bid_cost
    , sum(kd.ssp_bid_no_position_total_win_value) no_pt_yes_bid_cost
	, sum(kd.ssp_bid_position_total_win_value) pt_yes_bid_cost
    , sum(kd.impressions_with_wins) wins
    , max(r.cost) cost
    , max(r.profit+r.cost) revenue
from kmn_layouts l 
inner join kmn_kbidder_data kd on (kd.placement_id=l.layoutid)
inner join kmn_tag_report r on (r.tagid=kd.placement_id and r.date=date(kd.hour))
inner join kmn_sites s using(siteid)
inner join kmn_header_bidding_placement hbp on(hbp.placement_id=kd.placement_id)

where 
l.placement_kind='kbidder'
and r.date between '2016-09-29' and '2016-10-03'
group by sitename, tag_url, name, date
