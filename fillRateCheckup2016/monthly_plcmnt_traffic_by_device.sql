select year(date) year_
	, month(date) month_
	, placement_id
    , sum(mobile_traffic_count/mobile_traffic_percentage) mobile_traffic
	, ifnull(sum(mobile_traffic_count/(1-mobile_traffic_percentage)),0) nonmobile_traffic
    , if(
		sum(mobile_traffic_count/mobile_traffic_percentage)/ 
		ifnull(sum(mobile_traffic_count/(1-mobile_traffic_percentage)),0.1)  < 0.2
        , 'desktop'
        , if(
		sum(mobile_traffic_count/mobile_traffic_percentage)/ 
		ifnull(sum(mobile_traffic_count/(1-mobile_traffic_percentage)),0.1)  > 5
        , 'mobile'
        , 'mixed'
        ) 
	) placement_type
      
from kmn_feature_traffic
where placement_id regexp '[0-9a-f]{32}'
and (mobile_traffic_count>1)
group by year_, month_, placement_id;

select count(1) from kmn_feature_traffic;

select year('2015-05-22')
