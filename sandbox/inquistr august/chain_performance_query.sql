--set @placement_list = '19825960852f114eccbdaa18a0f02505,38ece84d79878b30ca01029bee5d0220,3aad7a7e4233fe8199fccb0320e2d33f,413d7d5b881d72a9fd4523854acfed81,88b92085a8bed9fafaa466e069662774,99db2396976f7c3ae91ce1effc2f4d8e,ab1eaf415e09e697d2b1b29d95030c20,df297f89097518c74a002a2f5afd0d91,ee14eadb4cfa28521b1492935c80e42c,f74a2780c46f4559298e0dc8d5ab3bc3';
--set @placemenet_list_comment ='Billboard.com';

set @placement_list = '003e92f85d2c54bfa5b90c13de260bb0,007f3a45ebb73838c1d7628d4b9dbb05,00b6610c009ae3ec9d4bcd2ea1e92c56,010ab4ddf80723c6ee63b561eb07ae6f,01550b70409ce6172ebf454bcc0b0f54,01fcfd1141916677f7ce61739ba9d5df,029202c4b211a5b4b5662668288511c2,036ffa7812faadfbe9b6f2342e80d8e6,037657001351a2a22c30b7c271c51e49,03d66e8845aa4624e39ebf7a1a3d4552';  -- suspicious zero served
set @placement_list = '0d36065e45e22ca8955e26b491f9843f,12e90a36ea70e4a58f0eda1033108a87,14090b08693166a6a1bd737811c9fa4b,1e7d4d6cc0252d496c9bd3af80db63ed,219affc912ba5f6782fcd9c96a268f06,29fb5b72175a9429f17c7ff36e64568b,2c63cd44fa10990f1e8f571f9e12ed5e,3168055598cf9414d239ae592b30bc5a,428b0312910695e96411f89bff0848cd,438d06f945b42aa24a3b17d69a47867e,4b04804bad88916ba26f4cf747b98a14,4dbf92819ea9f8b5b30db46adefe6aa1,53f8b3ca4ba11a924ba614a85f6fc50d,5d5830bef64c447270e3cb9f9a99757f,7a04c0dfa4f4871328de1dd741595012,7baaf0737dd792af7baa94854f54a346,8155f5188867767a6be3c9dc02895568,8b05c5124c41fa29c85fd84e0e9c611f,9de9415d2b34d93155f1938250a1885e,a09bac17d8c88cfea2bfba45d58ef0d4,ace5cf45d1bcd91d77eeb0b86d5bc2a4,b1ec42b7118e96f5207adec4ff3e499a,bb5fbea4220c3bf441dc59019095aeca,d019d0054972a65f86dd4bff5300066a,d0f8134c4f6ff74ed03450876e7eccb5,d9b871fdc444c5516bcbb107eb372685,da7123ac532f69c7b9f24c2f0e9376ea,e664d057e00d2e7e52da4e25e8bda1a4,e6fa8fd19d8e8427b4ae971e18801083,ec2909d439a84ad5ac2dd73e3bbe9d46,ee77ef2d2ad971aabdfc1ecc0704036d,f00019f2884c910add451cc251ce2307,f1c180f4837033a5b6bb2fbf39b27513';
set @placement_list = '052e4c3d9d5de022643b67cceebdc74a,8d7bb84524abce2d3bad1905e5bd8ce6,be24d4dbbb44f4cd3e8d4ed1cec442e9';
set @placemenet_list_comment ='NGames.com';
set @start_date = '2016-09-10';

select  distinct layoutid
from (select tagid layoutid from kmn_tag_report where date >= '2016-09-10' and impressions > 100 and served >10 group by tagid) r
inner join kmn_layouts l using(layoutid)
inner join kmn_ads_network an using(layoutid)
where an.type='smaato';
-- set @placement_list='328c2472f5257df2697b5908932619e0,371960ca1872757895184fc2a704e76a,6e353182dfb4514f2a7924953a0c4d70,9ce0d38850bfa5349e46f90e4f46b5b7,a28b4de4f73ba41337c87b1a4f739437,f4046cd90b36b7fabb61a7c37b2bd933'; 
select 'tag-chain-imps-gap' subject 
    , cr.placement_id
  	, cr.chain_codes
    , cr.date
    , cr.impressions impressions
    , cr.served
    , cr.house
    , find_in_set(a.code,replace(cr.chain_codes,':',',')) place
    , a.code tag_code
    , a.entity_type
  	, a.tag_impressions
    , a.served tag_served
    , round(1000*a.income/a.served,2) tag_ecpm
    , a.served/cr.impressions tag_fill_contrib
    , 1000*a.income/cr.impressions tag_rcpm_contrib
from kmn_chain_report cr
left join (
	select c.tagid placement_id, ad.code,c.date,c.impressions tag_impressions, c.served,c.income, ad.entity_type
    from kmn_cpm c force index(idx_timestamp)
    inner join kmn_ads_network ad on (c.ads_network_id=ad.id)
    where find_in_set(tagid,@placement_list)>0 
	-- tagid in (select layoutid from kmn_layouts where siteid='35a97f28bd5020da264fd9dcf23a49c4') 
    and c.timestamp >= unix_timestamp(@start_date)
    ) a on 
		  cr.placement_id = a.placement_id 
		    and concat(':',chain_codes,':') like concat('%:',a.code,':%') 
        and a.date=cr.date
where 
	find_in_set(cr.placement_id,@placement_list)>0
  --cr.placement_id in (select layoutid from kmn_layouts where siteid='35a97f28bd5020da264fd9dcf23a49c4')
  and cr.date >=@start_date
 order by placement_id, cr.date, impressions desc, place;
 
select placement_id, date, chain_codes,impressions, served
from kmn_chain_report cr
where 
	find_in_set(cr.placement_id,@placement_list)>0
 and cr.date >=@start_date
 limit 100;

 
select @placemenet_list_comment;
select @placement_list;
select @start_date;


select * from kmn_layouts
where find_in_set(layoutid,@placement_list)>0;


	select c.tagid placement_id, ad.code,c.date,c.impressions tag_impressions, c.served,c.income, ad.entity_type
    from kmn_cpm c force index(idx_timestamp)
    inner join kmn_ads_network ad on (c.ads_network_id=ad.id)
    where find_in_set(tagid,@placement_list)>0 
	-- tagid in (select layoutid from kmn_layouts where siteid='35a97f28bd5020da264fd9dcf23a49c4') 
  and c.timestamp >= unix_timestamp(@start_date)
    limit 100
    

;
set @placement_list='612bf0ce5b7a2b3663fd4639a0b92ff9,695a87b44affeba05510f7d9f50064f8,6a801da136fadeb06cc947b750757d07,d276bc69a488113641457ec072486521,d292be2b9723dfb3f23e5e0c0337ae5c,d6438fb3e807656a53ffa9fed3815e7e,189e71b0d75dd371c4791a3bf519c1f0,6790a0d1687e1738747c734670143352,8474769607e7013ad2e4096b24f04621,8570014ecfbd2bdd0ebac291c8b6aa94,a90f4c2a03abc5f2d6ff27d9dc26924b,c990520b9476a25b9ca91bec40eb9dcf,fd6101a064c3cf4c25be50267d532f82,24a3ed456f166d9d40be11f810280398,b03932e56b9489faeeef674d605cecf6,50b475922ad5fe1bd24a64f78cd0710c,a925d1c4332bf883566ede292b92f600,b525dda00eb453c2ea469e022416985b,2b5c89c9dbd44a1eda37220b1d489c3b,10cef4926cce86f780f3891bfd376377,1dbdb767189e7bfa171110816e1ff00c,21f5fc4a2d7f0776a7ed39ef9a4e6ca3,35298edd886a40527a450317e6192522,3a44893b2ff65af8cb6dfe1d3d072010,444f17a5395aed6fc64cc8a0ec89aece,4bb2e0898b265a59777742f61cdf0ccd,50569764ce06243950f54974c314fc23,55574c24d7a2a74ee7b5baf93ddedb33,6d2c5a927ef122f7cd89b3a6bc7378e0,71971b9205ceb6ee1fa4ae5a61ddf0a3,79bb5502735e2032fb35afd4e6d39ed8,909a1ce2de9b357c15ece9ecb4616ba9,9d9211da25b8a2e50c46be3f849c0f7b,a03836c57ae3051bfd956f330d72ed7f,b2014e798b799c1176d86a0b7fd509d1,cde0eadbcde063ac938a6ddef8bd1765,14d2f07ee3d6f640dbb57822d4b1476c,323d75e9985666427095caa40b4386af,48530c4ee5af7a1b591dff78c12b5490,6da1a091ce6b2228639cb9cbb980640a,869f323c563c5aedbf3cbed9c70ddea0,a9a9c05a3c010c3fe7bbe385eb5755f3,d7740501b1288191f17e0a79fa5ef2fb,dd1c1c8c1c653d18a859559f1e785d94,547ccb850c53c0aa55fe880793f43c3d,833d2778c9477dd5f86eef004eb0b6c6,2d279cc73220d9338f0535bfe2602524,b92a4b87b252aba59d2ac80d6fe2f9db,a70ffb1c9d1c161d9f5f55e171d9a872,0c5c5cb576a5a2944d65123a1f5193f1,a0f7a5415baecb3926d32c1ad11c34d2,07a73b14e6f428b5eb7f0cc3dd8ff3c8,11ec544c229aead02630f57dfaacd542,27ac8a8184e9125d70eb7368a9deeaf8,7e1716a7f92367a45a823c9520c368f8,052e4c3d9d5de022643b67cceebdc74a,be24d4dbbb44f4cd3e8d4ed1cec442e9,ce0b4df6f0fb9cf99bfaf50c14dead22,2d801e7d9e2ffd25b5e05d32a0c8a8c4,b49250ccadff015dd14230177cde1ac2,f11b87a0f7bb7a7a625359dffb733b6c,29664500057fe58152a6e9a8adecaf89,8d3f5e615a7251daeeac5fc39e2e3e79,bd74d8216092119afbcaac5c0ada7bc5,8d7bb84524abce2d3bad1905e5bd8ce6,a0a6ff8c1bf1f6fc9f4b736b8138547c';

select 
