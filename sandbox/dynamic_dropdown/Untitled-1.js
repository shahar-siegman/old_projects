const fs = require('fs');
var csv = require('fast-csv');
var moment = require('moment');
var csvWriter = require('csv-write-stream');
var writer = csvWriter()
var mysql=require('mysql')

var con =mysql.createConnection
