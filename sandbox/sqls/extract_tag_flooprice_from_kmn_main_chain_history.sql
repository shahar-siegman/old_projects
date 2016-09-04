SELECT * FROM komoona_db.kmn_report_estimation_network_factor;

select chain_name, 
right(chain_name,length(chain_name)-locate('e1',chain_name)-length('e1')) k,
if(locate('e1',chain_name)>0,
		substring(chain_name,
		locate('e1',chain_name)+length('e1')+1,
		locate(':',right(concat(chain_name,':'),length(chain_name)-locate('e1',chain_name)-length('e1'))))
        ,
        null) t


 from kmn_main_chain_history
where ad_network_id in 
('427f5c0e6c8246b0d1a2e75641936303',
'1e1ac744fa74012289a56b3835bad0cc',
'f2c03ce6592452b027614b82f0998db9',
'25e4b4876d86df8e5c0a900c52850b2d',
'160ee9642a26d477a906b065ecab1491',
'4937a8c1cba04a0f161b481ff22bb059',
'e2037e27e0c3f141930e9c6b960080b5',
'a687ff91cf158b3fb9ec0e37c9f86bc1',
'b8ce88d8908dab49d70a3fb8114b08a4',
'ffc012edce01d8bb5e42348a874aa4e4',
'3f3d49692c003aa91ca65b92d37d44c1')