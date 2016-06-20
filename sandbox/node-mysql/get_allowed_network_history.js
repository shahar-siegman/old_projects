const fs = require('fs');
var csv = require('fast-csv');
var moment = require('moment');
var csvWriter = require('csv-write-stream');
var writer = csvWriter()
var mysql=require('mysql')
var stream = require('stream')
var site='';
var available={isIn:{}, isOut:{}};;
var row;

var con =mysql.createConnection({host: "devdb.komoona.com", 
    user:"komoona",
    password:"eunubv2010",
    database: "komoona_db"});

writer.pipe(fs.createWriteStream('site_available_networks_largest.csv'));

var availableNetworkStream= new stream.Writable({highWaterMark: 200, objectMode:true});
availableNetworkStream._write=function(chunk,encoding,callback){
    var toFile=false;
    if(chunk.site!=site) {
        toFile=true;
        site=chunk.site;
        available={isIn:{}, isOut:{}};
    }
    else if(moment(chunk.timestamp).format("YYYY-MM-DD")!=row.timestamp)
        toFile=true;
    if (row && toFile)
        writer.write(row);
    row=processRow(chunk, available);
    
    callback();
}

var qStream=con.query("select site, timestamp, network, status \
from kmn_available_networks \
where network in ('pubmatic','pulsepoint','openx','aol','smaato','index')\
order by site, timestamp").stream();

qStream.pipe(availableNetworkStream);
qStream.on('end', finishUp)

function finishUp()
 { 
     availableNetworkStream.end(); 
     writer.end(); 
     con.end();
}

function processRow(row, available)
{
    if (row.status==1) {
        available.isIn[row.network]='';
        delete available.isOut[row.network];
    }
    else
    {
        available.isOut[row.network]='';
        delete available.isIn[row.network];
    }
    var netArray=Object.keys(available.isIn).sort();
    row.available=netArray.join(';');
    row.num = netArray.length; 
    row.timestamp=moment(row.timestamp).format("YYYY-MM-DD");
    return row; 
}





