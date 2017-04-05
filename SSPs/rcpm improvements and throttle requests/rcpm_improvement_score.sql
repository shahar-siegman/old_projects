delete from  tmp_domain_network_cpm ;
alter table tmp_domain_network_cpm add column (siteid char(32), sitename varchar(127));
alter table tmp_domain_network_cpm add primary key (siteid, domain, network);

insert into tmp_domain_network_cpm
select replace(substring_index(l.tag_url,'//',-1),'www.','') domain,
    'pubmatic' network,
	date_sub(final_date, interval 6 day) start_date,
    final_date end_date,
	sum(p.impressions) impressions,
    sum(p.income) revenue,
    siteid,
	sitename
from kmn_layouts l
inner join kmn_sites s using(siteid)
inner join (
	select tagid, 
    sum(impressions) impressions, 
    sum(income) income,
    final.date final_date
    from kmn_cpm c 
    inner join kmn_report_final_date final on final.type='final' and c.timestamp >= unix_timestamp(date_sub(final.date,interval 7 day))
	where c.date between date_sub(final.date,interval 6 day) and final.date
    and c.type='pubmatic'
    group by tagid) p on p.tagid= l.layoutid
    
group by siteid, domain;


select siteid,
	sitename account,
    domain,
	impressions,
    round(revenue,2) pubmatic_revenue,
	round(1000*revenue/impressions,5) pubmatic_rcpm,
    round(b.domain_revenue,2) account_domain_revenue,
    round(b.domain_kb_revenue,2) account_domain_kb_revenue,
	concat(round(100*((1-revenue/total_revenue) / (1-impressions/total_imps) -1),1) ,'%') rcpm_potential_improvement
from tmp_domain_network_cpm dn
inner join 
	(select sum(impressions) total_imps, sum(revenue) total_revenue from tmp_domain_network_cpm
    where network='pubmatic') openx_total
inner join 
	(select replace(substring_index(l.tag_url,'//',-1),'www.','') domain,
    siteid,
		sum(if(l.placement_kind is not null and l.placement_kind='kbidder', cost+profit,0)) domain_kb_revenue,
        sum(cost+profit) domain_revenue
	from kmn_tag_report r
    inner join kmn_layouts l on l.layoutid =r.tagid
    inner join kmn_report_final_date final on final.type='final'
    where r.date between date_sub(final.date,interval 6 day) and final.date
    group by siteid, domain) b using(siteid,domain)
    where network='pubmatic'
order by (1-revenue/total_revenue) / (1-impressions/total_imps)  desc


