select layoutid
	, name
    , replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
    , date
    , imps
    , pt_imps
    , pt_wins
    , served
    , rs_served
    , income
    , cost
    , round(if(served>2, 1000*income/served,0),3) income_ecpm
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
inner join kmn_layouts l using(layoutid)
left join 	( 
    select placement_id
    , date(hour) date_
    , sum(impressions) imps
    , sum(no_bid_position_impressions) pt_imps
    , sum(no_bid_position_impressions_with_wins) pt_wins
    , sum(no_bid_position_total_win_value) cost
    , sum(no_bid_position_taking_served_chains) rs_served
    from kmn_kbidder_data
    where find_in_set(placement_id, @placement_list)>0
    and hour>='2016-09-25'
	group by placement_id, date_) cost_t on revenue_t.layoutid=cost_t.placement_id and revenue_t.date=cost_t.date_


;

select tagid, income, served, from_unixtime(timestamp),date
from kmn_cpm
where find_in_set(tagid,@placement_list)>0
and timestamp>=unix_timestamp('2016-09-30');

set @placement_list='fea197961cf5984193fbe9a0a339e015,4afaa36d35278586ce12f73d4d57ec03,77f3e397d956090ca41d537e94de9ee0,d40ade307be194486502e5aeb5bbc594,3fe0fd006d3c2a96533c0378ffba323f,9f46182a57f5b919fc545b3b3a73a018,b3612258c3a7377cde78240571c661b1,0b2b1e012751fe245e12c4e8559f2384,dd5b744102d5a7971bdaae9c4d6847bf,bf6a7d021f90ae447e525160e4e193c7,25a4d1077595624738893c032d11c8a7,70c163d4380be32391a9088a3f0a8cbe,261cfaff734edf148027009277e278b5,0d4357c92f7d364a576f03cb2adf4f97,7fe4220347d7d06633e44aa1646e212e,c4e90bf280ec30e31246531bedb5bdbd,7f2dd173d8d77a1b4a7c7da9583d6c4e,34575f4602854358cfbe3d81f0187b74,7863347e1e749653d1090eecd2c6d9e6,3f6d6d431864096c6f0bafab88d0556d,e52cf4a3805089d644c84e634eba25bb,156d00234264b27e0423141e2e5ed4d9,e09a106783df12f3193045df48f6730b,bf560ed9afebe96e7ff5ca1409e151bf,12a2c5accd9a495223867740f4e5fe5f,10c8bdbe1d533be87fda0d0d7729d347,96971e8ab15f581e74b5c97f87bd3f81,5256e0bfbfbf20d10300094145493d78,016309ceb06f7490d6058783510dc6fe,8de9cc82cb758166e28d625bb639385b,2c1aa6bde170c390e14a20abdadb741b,8b5651c92931eced9e59a2592a22569d,8a727b186234d096e8ef8b7c1dd0e464,2b8a15a81844e169ad6eace6badde07f,125ecec4be22c905096a02c7402f27d6,e33e06694777d40093c01056252ac4fb,02883d3121062861bfc541569268b634,d024cae15830f84552b91fe879d93cbc,6542cc644cb1a58370617ec671e3d3f4,9489f03c6a8e05a307b39bbc7aba0720,49d5c955a3ee8a7ef61a184934409376,70cf4077cfee9d9205eb52c7c9f7565a,668bb88dcfa6f8c6c357c02e15c741a6,43d400179f0b10646a2417a9495d3652,5a1d2008609e0930ef4d443540aaf4cb,ffdf708d6f449c174924c4f091ff86e6,64a53d859603a95ce4ca979f1ab1c6bc,0cf06b0f52e874ad2294d30fb1f2fba6,1c66fbf2f0e357e5499af1ae59680ee8,342bda538b0f9d8618404e222e0a730e,aa7499d7e46ae4dbd15bb977e89d48a7,4424cc0c7e18486c22fb6de383482b32,f7c6a4bdc4ea0454404bf6b069af5211'