select * from (
	select placement_id, date(hour) day, sum(hb_served) hb_served
	from kmn_header_bidding_data
	where placement_id in ('078143e864a6a39a6a14682b4bb6944a','da77ba37d7902bcf04c95b1110046758')
	group by placement_id, day
	) a
left join (
	select placement_id, date(hour) day, sum(wins) wins
    from kmn_header_bidding_network_data
    where placement_id in ('078143e864a6a39a6a14682b4bb6944a','da77ba37d7902bcf04c95b1110046758')
    group by placement_id, day
    ) b using(placement_id, day)