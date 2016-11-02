select placement_id
  , impression_id
  , estimated_timeout
  , max(case when rests < estimated_timeout then received_ssp_bid else 0 end) max_bid_suggested_to_timeout
  , max(case when rests between estimated_timeout and estimated_timeout+500 then received_ssp_bid else 0 end) max_bid_within_500ms_of_timeout
  , max(case when rests> estimated_timeout+500 then received_ssp_bid else 0 end) max_bid_after_500ms_of_timeout
from sent_bids
where timestamp between '2016-10-30 0:00' and  '2016-10-30 15:00' 
and received_ssp_bid is not null
and length(kb_sold_tag)>0
group by placement_id, impression_id, estimated_timeout
order by placement_id, impression_id
