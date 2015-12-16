echo off
set file_dir=%CD%
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\pan.bat /level:Basic /file:"%file_dir%\combine_to_single_csv.ktr" 
popd
