select network, type from 
(select distinct pnd.network
from kmn_kbidder_placement_network_data pnd
WHERE
        placement_id IN ('4a132f8f47f382d3bb09d44e628e0d19' , 'ff84ddc3f6041825a7a9ff7641e572ac', '2637deec99bf9be3d3a5ecdd9ca6255e', 'b87b8dcb124534116ced56b27d7ec330')
            AND hour >= '2017-03-29' ) a
left join (
	select distinct c.type
    from kmn_cpm c
	INNER JOIN kmn_ads_network an ON an.id = c.ads_network_id
	WHERE
        tagid IN ('4a132f8f47f382d3bb09d44e628e0d19' , 'ff84ddc3f6041825a7a9ff7641e572ac', '2637deec99bf9be3d3a5ecdd9ca6255e', 'b87b8dcb124534116ced56b27d7ec330')
	and timestamp >= unix_timestamp('2017-03-28')
    and an.entity_Type = 'hbtag'
    ) b on b.type = a.network
;
SELECT 
    date_,
    placement_id,
    a.network,
    COUNT(1) tags,
    a.imps pnd_imps,
    SUM(c.impressions) cpm_imps,
    r.impressions tag_report_impressions,
    SUM(c.served) cpm_served,
    a.external_wins
FROM
    (SELECT 
        placement_id,
            DATE(hour) date_,
            network,
            SUM(total_impressions) imps,
            SUM(external_wins) external_wins
    FROM
        kmn_kbidder_placement_network_data pnd
    WHERE
        placement_id IN ('4a132f8f47f382d3bb09d44e628e0d19' , 'ff84ddc3f6041825a7a9ff7641e572ac', '2637deec99bf9be3d3a5ecdd9ca6255e', 'b87b8dcb124534116ced56b27d7ec330')
            AND hour >= '2017-03-29'
    GROUP BY placement_id , date_, network) a
        inner JOIN
    kmn_cpm c ON c.date = a.date_
        AND c.tagid = a.placement_id
        AND c.type = a.network
        INNER JOIN
    kmn_ads_network an ON an.id = c.ads_network_id
        INNER JOIN
    kmn_tag_report r ON r.date = a.date_
        AND r.tagid = a.placement_id
WHERE
    c.timestamp >= UNIX_TIMESTAMP('2017-03-28')
        AND an.entity_Type = 'hbtag'
        and c.type in ('pubmatic','defy','sovrn')
GROUP BY placement_id , a.network , date_