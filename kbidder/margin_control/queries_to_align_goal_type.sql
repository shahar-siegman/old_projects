-- insert into tmp_shahar_placement_goal_type_change 
select null, '2017-02-22', layoutid, optimization_goal_id, 8 new_goal_id
from kmn_layouts l
inner join kmn_tag_report r on r.tagid=l.layoutid
where l.placement_kind='kbidder'
and r.date = '2017-02-19'
and r.cost + r.profit > 0.01
and l.optimization_goal_id !=8;



select *
from tmp_shahar_placement_goal_type_change
where date=current_date;
select unix_timestamp(); -- 1487766219

start transaction;
rollback;
commit;

update kmn_layouts l, tmp_shahar_placement_goal_type_change sgt
set l.optimization_goal_id=sgt.new_goal_id
where sgt.layoutid=l.layoutid
and l.optimization_goal_id != sgt.new_goal_id
and sgt.new_goal_id is not null
and sgt.date=current_date;

insert into kmn_history (change_id, entity_type, entity_id, field, new_value, old_value, updated_by, note, timestamp)
select md5(rand()) change_id,'placement' entity_type ,layoutid entity_id,'optimization_goal_id' field, new_goal_id new_value, optimization_goal_id old_value,'shahar@komoona.com' updated_by,'align all kbidder' note,1487766219 timestamp
from tmp_shahar_placement_goal_type_change sgt
where sgt.date=current_date;

insert ignore into kmn_kbidder_feedback_factors
select layoutid, 0.12
from kmn_layouts l
inner join kmn_tag_report r on r.tagid=l.layoutid
where r.date = '2017-02-19'
and r.cost + r.profit > 0.01
and l.placement_kind='kbidder'