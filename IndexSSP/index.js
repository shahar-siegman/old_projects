var fs = require('fs');
var byline = require('byline');
var async = require("async");
var _ = require("underscore");


var logFile = 's2s1_statLog.log.2015-09-07-08';
var writePath = "placement_bids\\";
var data = {};
var fileCount = 0;
var processedCount = 0;

function processFile(logFile, cb) {
	var inStream = byline(fs.createReadStream(logFile), { encoding: 'utf8' });

	inStream.on('data', function(line) {
	  var requestData = JSON.parse(line);
	  if (!data[requestData.tagid])
	  	data[requestData.tagid] = [];	
	  data[requestData.tagid].push({returnCode: requestData.returnCodes, floor: requestData.fprice, bids: (requestData.bids)?(requestData.bids):(["0"])});
	  //console.log("dbg: bids=" + ((requestData.bids)?(requestData.bids):(["0"])).join(";"));
	});

	inStream.on('end', cb);
}

function writeData(err) {
	if (err)
		throw err;
	console.log("writing data");
	for (var placement in data) {
		var outFile = writePath + placement + ".csv";
		console.log("writing " + outFile);
		var wstream = fs.createWriteStream(outFile);

		for (var req in data[placement]) {
			var requestData = data[placement][req];
			var lineData = [requestData.bids.join(";"), requestData.floor, requestData.returnCode];
			wstream.write(lineData.join(",") + "\n");

		}

		wstream.end();		
	}
}

function processDir(path) {
	fs.readdir(path, function(err, files) {
		if (err)
			throw err;

		var fullFiles = _.map(files, function(f) {return path + "\\" + f});	

		console.log("processing %s log files", fullFiles.length);
		async.each(fullFiles, processFile, writeData);		
	} );
}

processDir("logFiles\\");

