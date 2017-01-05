select placement_id, count(1) impression, sum(case when with_bid>0 then 1 else 0 end) with_bid, sum(case when with_any_bid>0 then 1 else 0 end) with_any_bid 
from (
  select placement_id, impression_id, sum(case when received_ssp_bid>=0.03 then 1 else 0 end) with_bid,sum(case when received_ssp_bid>=0.01 then 1 else 0 end) with_any_bid
  from sent_bids
  where "timestamp" between '2016-12-06' and '2016-12-07'
  and placement_id in ('5f17316bfc008235a0886b0644e817b5','a83a5f8fc8794bf772a27e8df996ff4c','24c4a2e4125671bba257836e58644f78','34898ab15562a9c15fe40ff046276d82',
  '7169cc306d88dcea1f2b0e293e15ef0f','676882fd5dfbaa1065f8e21fc0a2323b','c9f25cceb06a1224762b1782651e3905')
  group by placement_id, impression_id 
 )
 group by placement_id;





5f17316bfc008235a0886b0644e817b5
a83a5f8fc8794bf772a27e8df996ff4c
24c4a2e4125671bba257836e58644f78
34898ab15562a9c15fe40ff046276d82
7169cc306d88dcea1f2b0e293e15ef0f
676882fd5dfbaa1065f8e21fc0a2323b
c9f25cceb06a1224762b1782651e3905
5f17316bfc008235a0886b0644e817b5
a83a5f8fc8794bf772a27e8df996ff4c
24c4a2e4125671bba257836e58644f78
34898ab15562a9c15fe40ff046276d82
7169cc306d88dcea1f2b0e293e15ef0f
676882fd5dfbaa1065f8e21fc0a2323b
c9f25cceb06a1224762b1782651e3905
