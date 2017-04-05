
select placement_id, 
  round(rests,-2) round_rests,
    round(received_ssp_bid*(1-
    case when network='pubmatic' then 0.08 when network='defy' then 0.36 else 0 end)) round_bid,
  received_ssp_bid,
  case when network='pubmatic' then 0.08 when network='defy' then 0.36 else 0 end commission,
  rests,
  case when kb_sold_tag='' then 1 when sent_bid > kb_sold_cpm  then 0 else 1 end available_bids,
  case when kb_sold_tag=code then 1 else 0 end win 
from sent_bids
where placement_id in ('2c3ceb4934806bcf2bd78c8b7e2e4dc4',
'eeab415bc944d6fde806e32b27bd1927',
'd0282c28148c3a43734983c0fa3f03fe',
'e247fe0e6fff8a1719d175673e164235',
'c4e90bf280ec30e31246531bedb5bdbd',
'e52cf4a3805089d644c84e634eba25bb',
'8de9cc82cb758166e28d625bb639385b',
'7f2dd173d8d77a1b4a7c7da9583d6c4e',
'9e399099241e3d7ceb24bc70230992ce',
'f6a2608aadba85ad032ca3d8e55fbd69',
'cc3886bf410d0f2220e4b90ab29393d3',
'6f0a932be12c90397bd5317b9193ad46',
'7fdfd213f45ab1ba0441d37114a9dc0d',
'b43c9e08c5ef8b1e5f99d4e3e81d1462',
'6c8125f4dae678a98302ae10d618ddcb',
'6f6280537ba6777f542559019758b0c7',
'0839dfe8f878cc63bf7735630a0e9231')
and sent_bid > 0
and "timestamp" between '2017-03-28 16:15' and '2017-03-28 18:15'
order by placement_id, round_rests, round_bid
