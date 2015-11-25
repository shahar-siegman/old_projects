create table mobile_experiment_11_11 as 
select placement_id
     , chain
     , trunc(timestamp) "date"
     , "timestamp"
	 , SPLIT_PART(served_chain, '|', -1) served_tag
     , length(served_chain) - length(replace(served_chain,'|','')) ordinal
     
     , SPLIT_PART(served_chain, '|', 1) initial_tag
     , served_chain
     ,	case when ua_browser_os='unknown' then 'unknown' else ua_device_type end ua_device_type
     , geo_continent
     , geo_country
     , final_state
     , ua_browser
     , ua_browser_ver
     , ua_browser_os
from aggregated_logs_5
where placement_id in ('0e42430f825c80036fd1b0a06f6425b9',
'1c8834441f20e22a0aef009c095a6cab',
'23d5b316d20d174c195ac34b655c9b1d',
'529b45adb160f3ad1b6c17b002f965d1',
'5b51ba18a5400094665c83330830c5d9',
'702cf021b8ace6f8cc306ecb0c5c8ff3',
'8840fe7e1463f84b96938b2c0ddbf2d6',
'91f27e5e07f3b8c0f824bb476cac2169',
'c58d4f9a96be20887e4142731e5fb85b',
'c5a6136df6d3e5c6d9c55f0b307d54e9',
'cbfd0f7b2f0c9a88093862f041c72407',
'de5d1317b63528fa12454589a916b50c')
and timestamp between '2015-10-22 00:00:00' and '2015-11-09 00:00:00';

