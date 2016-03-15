select placement_id
  , chain
  , trunc(timestamp) mydate
  , case when timestamp_stat1 is not null then 1 else 0 end is_ts_stat1
  , count(1) n
from aggregated_logs_5
where placement_id in ('053d8c8dc9286241db4d03b1211f9001',
'094b3589d9abde638cc8704400b65e12',
'198d689a49c618955a6fffc4e5d22fee',
'1d0bd2ec4e7928150392dee2a5d49a38',
'1e53715f5f205ec0f8787a0df1ba5d52',
'24524e6e197f3803d44abe0ba6a0b714',
'3ebb8e92d6d7d41f7672579242cafa63',
'529b45adb160f3ad1b6c17b002f965d1',
'544b57d715dd691cca18802e5dc8d993',
'5d68d72d7346bba331c58721bca1307b',
'640b543ade74bd55a5ae21b9e2779522',
'6e2bb23e183d1785fe338d0930b82488',
'9ae742991f451fb21c6369f45ac34829',
'a1e6274c3d9756935b4958248a9ed1e2',
'bab3a2b6c97481906df2ff0051906382',
'c360f219e5df557764af7aa946fb2bc2',
'cbfd0f7b2f0c9a88093862f041c72407',
'd4ecbb9d04fd598ea6ff2f9766a6f03a',
'd73d55c0e5968fc1381e0ac00317c5bf',
'de5c4d99131dc6e1f306c5e3687cb53d',
'f6694d8cfe48a96cde7404e91315440c',
'fed7e1ecb321991dea176156e264d810')
group by placement_id, chain, is_ts_stat1, mydate;


select * from aggregated_logs_5 limit 500;

select uid, client_ip, placement_id, count(uid) from aggregated_logs_5
where timestamp>= '2016-02-17 17:00' and timestamp <= '2016-02-17 20:00' 
group by uid, client_ip, placement_id
limit 500
