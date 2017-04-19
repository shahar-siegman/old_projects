SELECT 
    sitename,
    siteid,
    REPLACE(SUBSTRING_INDEX(l.tag_url, '//', - 1),
        'www.',
        '') domain,
	if(l.placement_kind is null OR l.placement_kind !='kbidder','waterfall','kbidder') is_kbidder,
    date,
    SUM(c.impressions) imps,
    SUM(served) served,
    SUM(income) revenue,
    1000 * SUM(income) / SUM(c.impressions) rcpm,
    count(1) ntags
FROM
    kmn_cpm c
        INNER JOIN
    kmn_layouts l ON l.layoutid = c.tagid
        INNER JOIN
    kmn_sites USING (siteid)
where c.type='pubmatic'
    and c.timestamp >= unix_timestamp('2017-02-01')
GROUP BY siteid, domain, date , is_kbidder
