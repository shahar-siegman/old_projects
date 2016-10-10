select 
  placement_id
  , "timestamp"
  , cb
  , geo_country
  , case when ua_device_type='M' then 'Mobile' else ua_device_type end device
  ,  final_state
 -- , case when length(pbsbids)>5 then least(floor( json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts')::decimal(10,2)/100)*100,5000) else 10000 end first_bid_ts
  , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'code'),1) kb_win_network1
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'sent_bid') kb_sent_bid1
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 0),'bid_ts') kb_sent_bid_ts1
  , left(json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'code'),1) kb_win_network2
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'sent_bid') kb_sent_bid2
  , json_extract_path_text(json_extract_array_element_text(pbsbids, 1),'bid_ts') kb_sent_bid_ts2
  , json_extract_path_text(a.hdbd_json,'o','rests') aol_response_time
  , json_extract_path_text(a.hdbd_json,'l','rests') cpx_response_time
  , json_extract_path_text(a.hdbd_json,'p','rests') pubmatic_response_time
  , json_extract_path_text(a.hdbd_json,'S','rests') Sovrn_response_time
  , json_extract_path_text(a.hdbd_json,'o','cpm') aol_bid
  , json_extract_path_text(a.hdbd_json,'l','cpm') cpx_bid
  , json_extract_path_text(a.hdbd_json,'p','cpm') pubmatic_bid
  , json_extract_path_text(a.hdbd_json,'S','cpm') Sovern_bid
  , json_extract_path_text(a.hdbd_json,'o','reqts') aol_request_time
  , json_extract_path_text(a.hdbd_json,'l','reqts') cpx_request_time
  , json_extract_path_text(a.hdbd_json,'p','reqts') pubmatic_request_time
  , json_extract_path_text(a.hdbd_json,'S','reqts') Sovern_request_time

  , case when strpos(a.hdbd_json, a.served_tag) = 1 and length(served_chain)>=4 then left(served_chain,length(served_chain)-3) else served_chain end served_chain_without_hb_tag
  , served_chain
  , replace(original_chain,',','|') orig_chain
  , chain
  , case when length(kb_sold_cpm)>0 then 1 else 0 end kb_wins
  , case when length(a.served_tag)<2 then 0 else 1 end served
  , case when a.served_tag='h' then 1 else 0 end house
  , case when a.served_tag='' and a.timestamp_placement is null then '' when a.served_tag='' and a.timestamp_placement is not null then 'Unknown' 
      when a.served_tag='h' then '' when strpos(a.hdbd_json, a.served_tag) = 0 then 'chain' else 'hdbd' end served_tag_source
  , url
  , served_tag_network
  , kb_sold_cpm
  , cpm
from impressions a
where placement_id in ('002aa587a4f606b3a523fd962f21c12e',
'016309ceb06f7490d6058783510dc6fe',
'016ab310f67c5aeea3e9d98aa963bdd8',
'0389203b77a2b8764962039f9fd45757',
'04f8a8cd30353dd10a3095bd51ec55f8',
'0a86ad338f6232689e8d66b385d95f0e',
'0c8505ce452c69b96dcb8139c8fb35d1',
'0cf06b0f52e874ad2294d30fb1f2fba6',
'0d4357c92f7d364a576f03cb2adf4f97',
'0fc0cdf4e38c041f8f04978525977eb9',
'1095bb7bd081889e52557ef2f7f06c23',
'10c8bdbe1d533be87fda0d0d7729d347',
'125ecec4be22c905096a02c7402f27d6',
'156d00234264b27e0423141e2e5ed4d9',
'161fa81b11903df1d3247cb23e815ed2',
'162b0305f10969a928e0174f1c993757',
'173c0a6c24ae5518f45826d0844a2352',
'19281b26cfea7b4f53e367ae13c74536',
'1c66fbf2f0e357e5499af1ae59680ee8',
'21bc8352895cc74f8ee1e44d09830f31',
'22a160d3e89de398794b15b0a1177235',
'2b8a15a81844e169ad6eace6badde07f',
'2c18df199c69aa14a9653f3897d36f7c',
'2c1aa6bde170c390e14a20abdadb741b',
'2c3ceb4934806bcf2bd78c8b7e2e4dc4',
'02883d3121062861bfc541569268b634',
'342bda538b0f9d8618404e222e0a730e',
'34575f4602854358cfbe3d81f0187b74',
'351450df664c1c3dfe03615cd8e94188',
'3b5c82c482470332175c901b294942bb',
'3b90f4fb91f4aef7fd8a4776200895fe',
'3ce42f2e4518ff93e8ef37579296d56b',
'3e26d6c3498437e63257cb7d08bed820',
'3e5cb1662bb51da0795e48977826d427',
'40be4dd1231e303eff344e10db52da97',
'43d400179f0b10646a2417a9495d3652',
'4424cc0c7e18486c22fb6de383482b32',
'471f5cb35d465a4571a09aff4f6fbfaa',
'49d5c955a3ee8a7ef61a184934409376',
'4d8a1720166133d8e70de49c95427f7d',
'5256e0bfbfbf20d10300094145493d78',
'54bd8d12d0ff2458f693ecf5ee01ff27',
'54cd8345c779fde894b4a7c7ea7d2757',
'5748bda0b3c77f475cf176e0d2f89262',
'5856c2fd053a87e3bc4448c9bda15c6b',
'58eecf457c1145d59dc3b2c3782221d1',
'59471108581addfe21dad63fab776be0',
'596ec973247f4663b9610e252ea7ab58',
'5a1d2008609e0930ef4d443540aaf4cb',
'5b26c4c4dfaa1b2eab6480b6998d033a',
'5c312e17f768c831ac20170cd6386f8b',
'618b72d7736d15c54bcd599383021b93',
'62ab7a6ea27c8676c0774982ecc10b7e',
'64a53d859603a95ce4ca979f1ab1c6bc',
'6542cc644cb1a58370617ec671e3d3f4',
'660ef77e785fba90b4f604732912552e',
'668bb88dcfa6f8c6c357c02e15c741a6',
'67198db58b77e947c51e9a9e2a609c6c',
'6c71ef147b1282b8cda1226b5335a0c4',
'6ef2ea4f1e86bb91b867acbf240a256f',
'70ac32e419c769c4fb81dbef0bc626fe',
'70c163d4380be32391a9088a3f0a8cbe',
'70cf4077cfee9d9205eb52c7c9f7565a',
'736e7b3b15cfa46f031675660b0536f9',
'753258c6f932e5be7b103ba0d3dba214',
'754088270109c65dab2efdfd27487121',
'7712c5e82b5c60b3c96ce16cf54708eb',
'7998c3b76ced4f004049c1590a824c34',
'7e3d21bb7fc72731ab16d1dc9954f790',
'7ead4f60d42be17aa355e47cb3036591',
'7edcc6911480e531d79389fb83263ef3',
'7f2dd173d8d77a1b4a7c7da9583d6c4e',
'7fe4220347d7d06633e44aa1646e212e',
'8298d87595f75e81d75268f41351e667',
'87748d1638df013d506de41a0c60cebd',
'8a727b186234d096e8ef8b7c1dd0e464',
'8ad4fb30cf6e1ad6a75053a8297b3879',
'8aee067cadc7620585706e5e1efc5f14',
'8b5651c92931eced9e59a2592a22569d',
'8de9cc82cb758166e28d625bb639385b',
'8df579a9dac67c78fec83b8d3d9539c6',
'8f5683cfba9109c0850c75e7baa7ccba',
'8fbbec6fdd52d002e67460fb3f2be516',
'91b09764edc1bbdebb2739b9f23c3230',
'92728015ab39f5fd950c075988edb113',
'9489f03c6a8e05a307b39bbc7aba0720',
'96971e8ab15f581e74b5c97f87bd3f81',
'987939d5913b602aea9e1b9332b7f477',
'99917eafc501da9f27d113e9e0793ed3',
'9b38b18b6314a721a2b1a635041c59e1',
'9faba6634720dde6dd7deb15a677ffcc',
'a21fc9eb47a677b9888cb6e0e2485ab5',
'a2da7ea8210e3a4f74f20f0f046c895c',
'a2fd098cf9a5c563bc9e49bd4c501f77',
'a393a489f7dd468a6a53d12bae4a44a8',
'a92d5311440a51abee4788c243d7ed68',
'aa7499d7e46ae4dbd15bb977e89d48a7',
'ab648124e1336a2ead4fdd2ff2c0053f',
'ac11e64d95164cfce73f19207283a0fb',
'b22fedb28566a3f88cc945680edddd76',
'b3044acaa9550476f794c5161929e585',
'b43c9e08c5ef8b1e5f99d4e3e81d1462',
'b6206ad037f9ff41bf6a2046aa1eca62',
'b62887ebe9f21fa243145eb235b9fbf5',
'b721a117a5fa5d472ca2e2f0c8103544',
'b80c001d3d6975944037b9e5d224ff4f',
'b84f5c63126d513a993d8789ba607fec',
'b8ff58a1c04e0ac1186be5b45328b3b4',
'b96ee8ffda7a398267debd2f6b0c6df3',
'bb8d3ae7889004ac46ba779a6781ae3e',
'bdfd482eadfdee7884f0e0fc75e0ee67',
'bf6a7d021f90ae447e525160e4e193c7',
'c4e90bf280ec30e31246531bedb5bdbd',
'cbf135a406e348f8e6e9915f6b314db3',
'cc735ee0a2ad7658542396bdbad68e18',
'cf33f79cb125b829a1fcc8b4a1b482b8',
'd000a681c8effe5085b9ee689a583ac5',
'd024cae15830f84552b91fe879d93cbc',
'd0282c28148c3a43734983c0fa3f03fe',
'd1ff54d49d6896213c895173ab6ad7eb',
'd46a0c4aefbdf6e38d380ace324df803',
'd9e3350edb227c17e6c7599186eccf9a',
'dd5b744102d5a7971bdaae9c4d6847bf',
'df1a1a3c74fc42d297b3445983510879',
'dfc62602ceaef75a50926337f7eab60c',
'e052ba062f24ecc1d57aecfe4c93d494',
'e09a106783df12f3193045df48f6730b',
'e10f56de44af30524bef8ddf184bd076',
'e247fe0e6fff8a1719d175673e164235',
'e28a9bd76d72700bba5b4cd050500e21',
'e33e06694777d40093c01056252ac4fb',
'e343ad55318f4001614ff6c0787365e8',
'e52cf4a3805089d644c84e634eba25bb',
'e64dce529d7bf6f6674f68a113d79480',
'e6c2f468bd02d82dd531ffdf1e9d080c',
'e6e91b32650a6e97d15cccaac3440d99',
'eeab415bc944d6fde806e32b27bd1927',
'ef5576221abe0963bdafcb9149050d11',
'f266e081e4ca6d7a7b92af296a53bd22',
'f3ef1de52ef7a6d0221891066c3cf084',
'f632ef63683fedf2a1d6e36cb92dc02b',
'f7c026f9a925e88ac42dcf760be2766d',
'f7c6a4bdc4ea0454404bf6b069af5211',
'f924845f67152f877e2a2304c5052f2b',
'fc0851915b72c954e36a9afb886a340a',
'fd7f4d4510c32011df662f2a8c482d4c',
'fe6d36ec9fce306a967a7b439bbe095d',
'ffdf708d6f449c174924c4f091ff86e6')
and timestamp between '2016-10-03 00:00' and '2016-10-04 00:00'
limit 100000
;
length(a.hdbd_json)>5;

select hdbd_json, pbsbids,served_tag,chain,served_chain, kb_code
from impressions a
where timestamp between '2016-09-28 11:00' and '2016-09-28 11:05'
and length(a.hdbd_json)>5 
and length(a.pbsbids)>5 
and length(a.chain)>2
limit 100;
