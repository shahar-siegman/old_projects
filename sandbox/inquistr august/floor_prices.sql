select plcmnts.tagid 
	, date(dt.dt) date_
    , substring_index(group_concat(floor order by timestamp desc),',',1) floor_price
from (select layoutid tagid from kmn_layouts where find_in_set(layoutid,@placement_list)>0) plcmnts
join calendar dt on dt between @start_date and current_date()
left join kmn_floor_prices_history h 
    on h.date <= dt.dt
	and h.tagid=plcmnts.tagid
group by tagid, date_
order by tagid, date_;

insert into calendar (dt) values ('2016-09-02'),('2016-09-03'),('2016-09-04');

select max(dt)
from calendar;

select @placement_list;
select @start_date;

set @start_date = '2016-08-13';

set @placement_list = '2a6f833fe8f1fd53f0929b00f18fe9cd,fbdbaf1bf4c4bd78460fb070c8fa60b4,4d6917bb3e3082a58d3315161171a520,1e1c39c376372ddf17ce5e48b839c949,adf61c85eda7dd360d0818eafa91b706,ee3906b5a4a983cfa76f3859da849e10,d9a7a800e06d49eb5428d8196d3c0998,ff4fcbd0d53b4865647e8c55c00a587d,7d2048bad2007a75017238546fcf1d16,b8a6c739cbe84db237fb9c31042fea85,63f05eb27509a52e0fe6fd515ba73915,666c15e1c2b4e4c192ec14f17553a744,6e353182dfb4514f2a7924953a0c4d70,371960ca1872757895184fc2a704e76a,c360f219e5df557764af7aa946fb2bc2,f4046cd90b36b7fabb61a7c37b2bd933,a28b4de4f73ba41337c87b1a4f739437,474a6abf936899bc4f8f8d0b066398bc,9ce0d38850bfa5349e46f90e4f46b5b7,fae962f33668fc4d341f86bcf97a6bfb,fd3589722614c606caf142438f2f143c,8bb38abe72e66312d9e682ac7f3f5797,cc0d14b02ce3214a42fd63b51f9b13c0,328c2472f5257df2697b5908932619e0,22ebbcc01c64763f35aa9eb96831934f,617a74fc969438a702d9cc61cc730be3,261b40bc4bda65a70f80c51b41b66033,c4fd06c35b0c268a9c2fc42cae6f751d,8ec759d43db18c0d0ada24d9136d499c,31a71a4e96e9fb009696f2bc2c7a9ea5,9ae742991f451fb21c6369f45ac34829,7dfdcbe86e90be9431e6d8dcc6251daa,3fecdc2a03644a1b46ca7fa51b25218e,f13d38c2eb644eb7fbf81498618775aa,a470a60ee38cdc6b40d847c090c09320';
