echo off
echo placment_id %1
set file_dir=%CD%
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\pan.bat "/param:placement_id=%1" /level:Basic /file:"%file_dir%\current_allocations.ktr" 
popd
