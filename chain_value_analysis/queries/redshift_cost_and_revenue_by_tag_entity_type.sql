SELECT placement_id ,
       date_trunc('day',"timestamp")::date date_ ,
       CASE
           WHEN served_tag=kb_sold_tag THEN 'hbtag'
           WHEN served_tag_network='e' THEN 'postbid'
           WHEN served_tag='' THEN 'lost'
           WHEN served_tag='h' THEN 'filtered'
           ELSE 'adtag'
       END served_type,
       served_tag_network,
	   count(1) imps,
       round(sum(kb_sold_cpm)/1000,2) cost ,
       round(sum(cpm)/1000,2) revenue ,
       round(sum(received_ssp_bid)/1000,2) hb_tag_value
FROM sent_bids s
WHERE "timestamp" BETWEEN dateadd('d', -5, CURRENT_DATE) AND CURRENT_DATE
  AND code=kb_sold_tag
GROUP BY placement_id,
         date_,
         served_type,
         served_tag_network
ORDER BY date_,
         placement_id,
         served_type,
         served_tag_network
