var mysql = require('mysql');
var fs = require('fs');
var moment = require('moment');
var csv = require('fast-csv');

var dataFile='kbidder_updates_'+moment().format('YYYY-MM-DD-HH')+'.csv';
//var dataFile='kbidder_updates_2016-07-24-10.csv';

function BD() {
    var connection = mysql.createConnection({
        user: 'komoona',
        password: 'eunubv2010',
        host: 'komoona-db-az.cesnzoem9yag.us-east-1.rds.amazonaws.com',
        port: 3306,
        database: 'komoona_db'
    });
    console.log('Connected to mysql');
    return connection;
}



function loadData(dataFile) {
	fs.createReadStream(dataFile)
    .pipe(csv({headers: true}))
    .on("data", handleCsvLine)
    .on("end", function(){
        console.log("done reading from file");
        objBD.commit(function(err) { if (err) { objBD.rollback(function() {throw err; })}});
        objBD.end(function(f) {
            console.log("done closing connection");
        });
    });
}

function handleCsvLine(rsData)
{
       objBD.query('REPLACE INTO shahar_kbidder_placement_stats SET ?', rsData, 
       function(err, result) { 
           console.log("Processing line...");
           if (err)
                console.error(err); 
        });
}

var objBD = BD();
objBD.beginTransaction(function(err) {
    loadData(dataFile); 
});