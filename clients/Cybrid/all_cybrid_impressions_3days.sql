select
  placement_id
    , "timestamp"
    , date_trunc('day',"timestamp") date
    , cb
    , uid
    , chain
    , served_chain
    , served_tag
    , 1 impression
    , case when length(served_tag)>1 then 1 else 0 end served
    , geo_country
    , ua_browser
    , ua_browser_ver
    , ua_browser_os
    , ua_device_type
 from impressions
 where placement_id in ('18fb3faae01f48b9659ee19442bf1133',
'5b8dd5766143509ffe8de8d24183612d',
'5eeb6685ca2b5198e78186d6d3a90cb8',
'5f8b99283d572fe4f3f83aee8216046b',
'6636cba14af952b756537557a821b92a',
'67c5f95b2928a8449c89e6c9de6d25a6',
'7195de337fccdb8ac7207b71951d0690',
'943aece7d657f12dfb9b64fad573f5bb',
'9e5f84417d7909db9f35c143345e4e73',
'f673bfda58e7708128278e27277fb2df')
and "timestamp" between '2016-09-02' and '2016-09-05';

-- comparison client - moviestalk
('08a85e36f2f083c597b8c8e33c541b64',
'15ecd4130fd16bf408e5bd6282004e5f',
'1e41c4834fec0f6d3a586d33292220a8',
'547b3b7733b0947b5b0763c0bff7ee16',
'99ee6a81405ab9246e4adfd8b7c5ea0c')
