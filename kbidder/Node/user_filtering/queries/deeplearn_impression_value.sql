select 
  l.name,
  l.tag_url,
  s.placement_id,
  s.network,
  s.filtered,
  
  case when s.received_ssp_bid>0 then 1 else 0 end has_bid,
  case when left(s.kb_sold_tag,1)='e' and network='openx'
          or left(s.kb_sold_tag,1)='p' and network='pubmatic'
          or left(s.kb_sold_tag,1)='l' and network='cpx'
          or left(s.kb_sold_tag,1)='S' and network='sovrn'
          then 1 else 0 end has_win,
  s.received_ssp_bid,
  s.pc_wb,
  s.pc_res,
  s.rests,
  s."timestamp",
  
  i.geo_country,
  i.geo_continent,
  i.ua_browser,
  i.ua_browser_os,
  i.ua_device_type
  
  from sent_bids s
  inner join kmn_layouts l on l.layoutid = s.placement_id
  inner join impressions i on i.placement_id = s.placement_id and i.cb = s.cb and i.client_ip = s.client_ip
  and s.timestamp between '2017-06-12 10:00' and '2017-06-12 10:01'
  and s.placement_id in ('04fe83cd7b0a314d8e08433d2a5a6b60',
    '0642ead65fd84ad92d3917de057f79ef',
    '08a275db4970b76b1b017b24b2244a67',
    '211695f4beb42db8307dfd612c24104b',
    '28ee3b57ac8ce306c3e8a4ba45f1f563',
    '2f85eff0ca3e85a84473681c0e113cbe',
    '3080487bdfb51c46a06ad4408ef24512',
    '363a8f9254c5031f39b7b071ef1b464b',
    '3834375fef47b9e9fff8138eee1bfd1c',
    '4a132f8f47f382d3bb09d44e628e0d19',
    '5436130fe092f0d926e9581cdfa565f8',
    '54e67c9ae4c4b21312edeb029c41af13',
    '55eefbd2646d603139a7d7a4b4470739',
    '5b6d3090b4b6b0bb0f716d23dd2a2c83',
    '634de8b4faec8df53c3150299be8a012',
    '651cf262d3f0e19fbc1e4e5ae158c24f',
    '6c77ef5221fbb898aea49daa373574f7',
    '75e812b1dbb1f4e105741499e6752060',
    '76f91a6637cbb990f72049cece2cfa67',
    '794b998efb72b374ef36dcffeadd4b3f',
    '8079b22f0e2233ddb71eebcf0c2e6606',
    '84317a02d16174953ceade8c645335fe',
    '917f128f6595b73884be4153e686ad99',
    'a9cb5dee437efe3f6f2a215ace703f7e',
    'ad19ebbf458886c0437244f6832b32cc',
    'b3c796b1920993cec01f50caabfb560e',
    'b4485fc6076d2f56fb63129b80ae3f4b',
    'bafdbf66a01ce1c79d757cf1b4106074',
    'bb2138a0a4bf3640def63094d824abee',
    'be16b924cf1a9f5038bba9fdaa8a80c9',
    'cd1c6edabe54244e37657ac589d08a09',
    'd6bf05531c5a18a9e3a10c1a166a01ba',
    'd9fe42c7bbe21b644de5e9ffcd59a616',
    'ddef05ceb93e88450fec4278fc2d35bb',
    'df83941b360be793eed46b2972cdff0a')
;
