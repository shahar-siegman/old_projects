start transaction;
alter table kmn_optimization_goal
add column (tech_name char(32));

update kmn_optimization_goal 
set tech_name= 'A' where id=1;
update kmn_optimization_goal 
set tech_name= 'B' where id=2;
update kmn_optimization_goal 
set tech_name= 'C' where id=3;
update kmn_optimization_goal 
set tech_name= 'A+' where id=4;
update kmn_optimization_goal 
set tech_name= 'C+' where id=5;
update kmn_optimization_goal 
set tech_name= 'G' where id=6;
update kmn_optimization_goal 
set tech_name= 'G-' where id=7;
update kmn_optimization_goal 
set tech_name= 'KBidder' where id=8;
update kmn_optimization_goal 
set tech_name= 'A+ High Risk' where id=9;
update kmn_optimization_goal 
set tech_name= 'C 50% margin' where id=10;
commit; 





