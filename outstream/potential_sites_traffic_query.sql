SELECT 
    placement_id,
    SUM(IF(geo_us_ca = 'US', imps, 0)) us_impressions,
    SUM(IF(geo_us_ca = 'CA', imps, 0)) ca_impressions,
    SUM(IF(geo_us_ca = 'other', imps, 0)) other_impressions
FROM
    (SELECT 
        placement_id,
            CASE
                WHEN geo IN ('US' , 'CA') THEN geo
                ELSE 'other'
            END geo_us_ca,
            SUM(impressions) imps
    FROM
        kmn_traffic_features
    WHERE
        date BETWEEN DATE_SUB(CURDATE(), INTERVAL 15 DAY) AND DATE_SUB(CURDATE(), INTERVAL 2 DAY)
    GROUP BY placement_id , geo_us_ca) a
group by placement_id;
