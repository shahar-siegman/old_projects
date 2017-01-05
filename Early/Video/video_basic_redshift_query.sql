
select placement_id
     , client_ip
     , final_state
     , ua_browser
     , ua_browser_ver
     , ua_browser_os
     , ua_device_type
     , "timestamp"
     , video_vast_req_sent_ts
     , case video_vast_req_sent_ts is null when 1 then 0 
          else datediff ('secs',"TIMESTAMP",video_vast_req_sent_ts) END request_time
     , case video_vast_req_timeoutt_ts is null when 1 then 0 
          else datediff ('secs',"TIMESTAMP",video_vast_req_timeoutt_ts) END timeout_time
      , case video_tag_started_ts is null when 1 then 0 
          else datediff ('secs',"TIMESTAMP",video_tag_started_ts) END tag_start_time
      , case video_ad_cancel_ts is null when 1 then 0 
          else datediff ('secs',"TIMESTAMP",video_ad_cancel_ts) END cancel_time
      , case video_ad_start_ts is null when 1 then 0 
          else datediff ('secs',"TIMESTAMP",video_ad_start_ts) END ad_start_time
      , case video_ad_end_ts is null when 1 then 0 
          else datediff ('secs',"TIMESTAMP",video_ad_end_ts) END ad_end_time
      , case video_vast_req_sent_ts is null when 1 then 'none'
          else case video_tag_started_ts is null when 1 then 'request'
            else case video_ad_start_ts is null when 1 then 'tag_start'
                else case video_ad_end_ts is null when 1 then 'ad_start'
                  else 'ad_end' 
                     end
                  end
               end
          end
