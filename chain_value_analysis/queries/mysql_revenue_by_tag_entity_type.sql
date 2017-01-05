SELECT 	s.sitename,
		l.name,
		l.layoutid placement_id,
       c.date,
       an.entity_type,
       sum(c.impressions) impressions,
       concat(round(100*sum(c.served)/sum(c.impressions),1),'%') fill,
       round(sum(c.income),2) revenue
FROM kmn_cpm c
INNER JOIN kmn_layouts l ON l.layoutid=c.tagid
INNER JOIN kmn_sites s using(siteid)
INNER JOIN kmn_ads_network an ON an.id=c.ads_network_id
WHERE l.placement_kind='kbidder'
  AND c.date >= DATE_SUB(CURDATE(), INTERVAL 5 DAY)
GROUP BY an.entity_type, l.name,
         c.date ;

