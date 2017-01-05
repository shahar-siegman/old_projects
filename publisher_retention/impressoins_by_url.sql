SELECT siteid
    , replace(substring_index(l.tag_url,'//',-1),'www.','') clean_url
	, name
    , layoutid
	, r.impressions
FROM kmn_layouts l
inner join kmn_tag_report r on (r.tagid=l.layoutid)
where r.date='2016-11-12'
order by siteid, clean_url, impressions desc