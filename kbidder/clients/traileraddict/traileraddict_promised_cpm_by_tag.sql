select placement_id
  , date_trunc('day',"timestamp") date_
  , served_tag
  , count(1) impressions
  , sum(cpm) sum_cpm
from impressions
where placement_id in ('5a1d2008609e0930ef4d443540aaf4cb',
'64a53d859603a95ce4ca979f1ab1c6bc',
'342bda538b0f9d8618404e222e0a730e',
'43d400179f0b10646a2417a9495d3652',
'8a727b186234d096e8ef8b7c1dd0e464',
'ffdf708d6f449c174924c4f091ff86e6',
'125ecec4be22c905096a02c7402f27d6')
and timestamp>='2016-09-19'
group by placement_id, date_, served_tag;



select placementid, adtagid, an.code, date, sum(total_bids_cost), sum(total_promised_income), sum(impressions)
from kmn_kbidder_cpm c
inner join kmn_ads_network an on (an.id=c.adtagid)
where placementid in ('5a1d2008609e0930ef4d443540aaf4cb',
'64a53d859603a95ce4ca979f1ab1c6bc',
'342bda538b0f9d8618404e222e0a730e',
'43d400179f0b10646a2417a9495d3652',
'8a727b186234d096e8ef8b7c1dd0e464',
'ffdf708d6f449c174924c4f091ff86e6',
'125ecec4be22c905096a02c7402f27d6')
and date>='2016-09-15'
group by date;



select an.layoutid, c.date, an.code, impressions, served, income
from kmn_cpm c
inner join kmn_ads_network an on (an.id=c.ads_network_id)
where an.layoutid in ('5a1d2008609e0930ef4d443540aaf4cb',
'64a53d859603a95ce4ca979f1ab1c6bc',
'342bda538b0f9d8618404e222e0a730e',
'43d400179f0b10646a2417a9495d3652',
'8a727b186234d096e8ef8b7c1dd0e464',
'ffdf708d6f449c174924c4f091ff86e6',
'125ecec4be22c905096a02c7402f27d6')
and timestamp>=unix_timestamp('2016-09-16');




select layoutid
	, name
    , date(r.hour) date_
    , tag_url
    , header_bidding_id
    , sum(r.impressions) impressions
    , sum(r.impressions_with_bids) impressions_with_bids
    , sum(no_bid_position_impressions) no_bid_position_impressions
    , sum(ssp_bid_no_position_total_win_cpm) ssp_bid_no_position_total_win_cpm
    , sum(ssp_bid_no_position_taking_total_received_cpm) ssp_bid_no_position_taking_total_received_cpm
from kmn_layouts l
inner join kmn_header_bidding_placement p on (l.layoutid=p.placement_id)
left join kmn_kbidder_data r on (r.placement_id=l.layoutid and date(r.hour) between '2016-09-16' and '2016-09-22')
where l.siteid= '1ae8902c3a277cd7ed921ab7eaf81040'
group by layoutid, date_;

