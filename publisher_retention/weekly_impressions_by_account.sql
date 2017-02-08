
select s.sitename account, date_sub(date, interval weekday(date) day) date_monday, min(month(date)) month_, sum(r.impressions) impressions, sum(r.cost+r.profit) revenue
from kmn_tag_report r
inner join kmn_layouts l on l.layoutid=r.tagid
inner join kmn_sites s using (siteid)
inner join tmp_shahar_sites using(siteid)
group by account, date_monday

