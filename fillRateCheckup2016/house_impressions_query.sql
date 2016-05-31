select
	date
    , sum(if(chain_codes='h',impressions,0)) house_imps
    , sum(if(chain_codes!='h',impressions,0)) non_house_imps
    , sum(if(chain_codes!='h',served,0)) non_house_serve
from kmn_chain_report cr
where date >='2015-01-01'
group by date

