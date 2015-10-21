echo off
echo placment_id %1
pushd C:\Pentaho\data-integration
C:\Pentaho\data-integration\pan.bat "/param:placement_id=%1" /level:Basic /file:"C:\Shahar\Projects\Optimization\tag_performance_for_parallel.ktr" 
popd
