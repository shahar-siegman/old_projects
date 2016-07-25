moment=require('moment');

var aTime = moment('2016-07-03 01:02:03', 'YYYY-MM-DD HH:mm:ss')
var bTime = moment('Sun Jul 03 2016 01:02:03 GMT+0300 (Jerusalem Daylight Time)');

console.log(moment().format('YYYY-MM-DD HH:mm:ss'));

console.log(bTime.format('YYYY-MM-DD HH:mm:ss'));