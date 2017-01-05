echo off
echo running %1 >> C:\Shahar\Projects\Dashboard\log.txt
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\kitchen.bat "/param:transform=%1" "/level:Debug" "/file:C:\Shahar\Projects\Dashboard\run_with_date.kjb" >> C:\Shahar\Projects\Dashboard\log.txt
popd
