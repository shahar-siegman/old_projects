select layoutid
    , date
    , pt_imps
    , pt_wins
    , served
    , income
    , cost
    , round(if(served>3, 1000*income/served,0),3) income_ecpm
	, round(if(pt_wins>3,1000*cost/pt_wins,0),2) win_cpm
from (
	select layoutid, date, sum(served) served, sum(income) income
    from (
		select  a.layoutid
			, a.code
			, a.chain_name
			, c.date
			, substring_index(group_concat(a.chain_type order by a.startdate),',',-1) chain_type_on_date
			, max(c.served) served
			, max(c.income) income
		from kmn_cpm c force index (idx_timestamp)
		inner join (
			select an.layoutid, an.code,'main' as chain_type,startdate, ad_network_id, chain_name
			from kmn_main_chain_history mch
			inner join kmn_ads_network an on (an.id=mch.ad_network_id)
			where find_in_set(an.layoutid,@placement_list)>0
			and startdate>='2016-09-01'
			union
			select an.layoutid, an.code,'other', startdate, ad_network_id, chain_name
			from kmn_chain_history ch
			inner join kmn_ads_network an on (an.id=ch.ad_network_id)
			where find_in_set(an.layoutid,@placement_list)>0
			and startdate>='2016-09-01'
		) a on (c.ads_network_id=a.ad_network_id and c.timestamp>=unix_timestamp(date(a.startdate)) and c.tagid=a.layoutid)
		where c.timestamp >= unix_timestamp('2016-09-25')
		group by a.layoutid, a.code,c.date
        having chain_type_on_date='main'
) b group by layoutid, date
    ) revenue_t
left join 	( 
    select placement_id
    , date(hour) date_
    , sum(no_bid_position_impressions) pt_imps
    , sum(no_bid_position_impressions_with_wins) pt_wins
    , sum(no_bid_position_total_win_value) cost
    from kmn_kbidder_data
    where find_in_set(placement_id, @placement_list)>0
    and hour>='2016-09-25'
	group by placement_id, date_) cost_t on revenue_t.layoutid=cost_t.placement_id and revenue_t.date=cost_t.date_


;

select tagid, income, served, from_unixtime(timestamp),date
from kmn_cpm
where find_in_set(tagid,@placement_list)>0
and timestamp>=unix_timestamp('2016-09-30');

set @placement_list='016309ceb06f7490d6058783510dc6fe,0d4357c92f7d364a576f03cb2adf4f97,10c8bdbe1d533be87fda0d0d7729d347,156d00234264b27e0423141e2e5ed4d9,173c0a6c24ae5518f45826d0844a2352,1c66fbf2f0e357e5499af1ae59680ee8,2b8a15a81844e169ad6eace6badde07f,2c1aa6bde170c390e14a20abdadb741b,2c3ceb4934806bcf2bd78c8b7e2e4dc4,34575f4602854358cfbe3d81f0187b74,3b5c82c482470332175c901b294942bb,3f6d6d431864096c6f0bafab88d0556d,4424cc0c7e18486c22fb6de383482b32,49d5c955a3ee8a7ef61a184934409376,4afaa36d35278586ce12f73d4d57ec03,5256e0bfbfbf20d10300094145493d78,5748bda0b3c77f475cf176e0d2f89262,58eecf457c1145d59dc3b2c3782221d1,6542cc644cb1a58370617ec671e3d3f4,668bb88dcfa6f8c6c357c02e15c741a6,67198db58b77e947c51e9a9e2a609c6c,70c163d4380be32391a9088a3f0a8cbe,70cf4077cfee9d9205eb52c7c9f7565a,7863347e1e749653d1090eecd2c6d9e6,7edcc6911480e531d79389fb83263ef3,7f2dd173d8d77a1b4a7c7da9583d6c4e,7fe4220347d7d06633e44aa1646e212e,8b5651c92931eced9e59a2592a22569d,8de9cc82cb758166e28d625bb639385b,8df579a9dac67c78fec83b8d3d9539c6,9489f03c6a8e05a307b39bbc7aba0720,96971e8ab15f581e74b5c97f87bd3f81,9faba6634720dde6dd7deb15a677ffcc,aa7499d7e46ae4dbd15bb977e89d48a7,ac11e64d95164cfce73f19207283a0fb,b43c9e08c5ef8b1e5f99d4e3e81d1462,bf6a7d021f90ae447e525160e4e193c7,c4e90bf280ec30e31246531bedb5bdbd,d024cae15830f84552b91fe879d93cbc,d0282c28148c3a43734983c0fa3f03fe,d46a0c4aefbdf6e38d380ace324df803,d9e3350edb227c17e6c7599186eccf9a,dd5b744102d5a7971bdaae9c4d6847bf,e052ba062f24ecc1d57aecfe4c93d494,e09a106783df12f3193045df48f6730b,e247fe0e6fff8a1719d175673e164235,e28a9bd76d72700bba5b4cd050500e21,e33e06694777d40093c01056252ac4fb,e52cf4a3805089d644c84e634eba25bb,eeab415bc944d6fde806e32b27bd1927,f632ef63683fedf2a1d6e36cb92dc02b,f7c6a4bdc4ea0454404bf6b069af5211,fc0851915b72c954e36a9afb886a340a,fe6d36ec9fce306a967a7b439bbe095d'