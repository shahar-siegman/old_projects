echo off
echo placment_id %2
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\kitchen.bat "/param:transform=%1" "/level:Basic" "/file:C:\Shahar\Projects\Dashboard\run_with_date.kjb"
popd
