echo off
echo placment_id %2
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\pan.bat "/param:start_date=%1" "/param:placement_id=%2" /level:Basic /file:"C:\Shahar\Projects\tagData\chains_stat1_for_parallel.ktr" 
popd
