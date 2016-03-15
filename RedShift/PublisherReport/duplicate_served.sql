select placement_id
  , "timestamp"
  , client_ip
  , cb
  , uid
  , chain
  , served_chain
  , served_tag
  , insert_time
from aggregated_logs_5
where placement_id='842bf70073f2c15221727c355c88c089'
and trunc(timestamp) = '2016-02-20'
and (chain is not null and chain !='' OR served_tag is not null and served_tag!='') ;
