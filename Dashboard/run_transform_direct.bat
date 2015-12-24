echo off
echo running "/file:%1" "/level:Debug" "/param:%~2"
pushd C:\Pentaho\data-integration
call C:\Pentaho\data-integration\pan.bat "/file:%1" "/level:Debug" "/param:%~2"
popd
