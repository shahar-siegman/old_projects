echo off
set file_dir=%CD%
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\pan.bat /level:Basic /file:"%file_dir%\join floorprice history parallel.ktr" 
popd
