
select placement_id
     , "timestamp"
     , DATE_PART( 'hrs', "timestamp" ) hour_of_day
     , geo_continent
     , geo_country
     , final_state
     , ua_browser
     , ua_browser_ver
     , ua_browser_os
     , ua_device_type
     , video_vast_req_sent_ts
     , adtag_ts_list
     , served_chain
     , case video_vast_req_sent_ts is null when 1 then null 
          else datediff ('secs',"TIMESTAMP",video_vast_req_sent_ts) END request_time
     , case video_vast_req_timeoutt_ts is null when 1 then null 
          else datediff ('secs',"TIMESTAMP",video_vast_req_timeoutt_ts) END timeout_time
      , case video_tag_started_ts is null when 1 then null
          else datediff ('secs',"TIMESTAMP",video_tag_started_ts) END tag_start_time
      , case video_ad_cancel_ts is null when 1 then null
          else datediff ('secs',"TIMESTAMP",video_ad_cancel_ts) END cancel_time
      , case video_ad_start_ts is null when 1 then null
          else datediff ('secs',"TIMESTAMP",video_ad_start_ts) END ad_start_time
      , case video_ad_end_ts is null when 1 then null
          else datediff ('secs',"TIMESTAMP",video_ad_end_ts) END ad_end_time
      , case video_vast_req_sent_ts is null when 1 then '0 - video tag not run'
          else case video_tag_started_ts is null when 1 then '1 - player loaded'
            else case video_ad_start_ts is null when 1 then '2 - tag loaded'
                else case video_ad_end_ts is null when 1 then '3 - ad started'
                  else '4 - ad completed' 
                     end
                  end
               end
          end video_state
from aggregated_logs_5
where placement_id in ('1d0bd2ec4e7928150392dee2a5d49a38',
'19849c838672e47f7f6800545e1e9fd6',
'9ae742991f451fb21c6369f45ac34829',
'a24a4ba2c6d5bcb1c7cb23970f542e9a',
'c360f219e5df557764af7aa946fb2bc2',
'c25fb5bd8b899ca4f1dda884a4c6bb8b')
and timestamp between '2015-11-03 12:00:00' and '2015-11-04 12:00:00'
and served_chain like 'd%'
limit 80000
