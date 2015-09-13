var AWS = require('aws-sdk');
var async = require("async");
var _ = require("underscore");
var fs = require('fs');
var exec = require('child_process').exec;

var s3 	= new AWS.S3();
AWS.config.region = 'us-east-1';

var logsBucket = 'komoona-logs';
var zippedDir = "zippedLogFiles";
var logDir = "logFiles";
var zipExec = '"C:\\Program Files\\7-Zip\\7z.exe"';

var downloadCount = 24;

function listLogFilesAtDate(logsDate, cb)
{	
	var prefix = "s2s/" + logsDate;
	console.log("getting file list, bucket=%s, prefix=%s", logsBucket, prefix);

	s3.listObjects({Bucket: logsBucket, Prefix: prefix}, function(err, data) {
		if (err) {
			console.log("ERROR: " + err);
			cb(err);
		}

		cb(null, data.Contents);
	});
}


function downloadFile(fullPath, cb)
{

	var params = {
        Bucket : logsBucket,
        Key    : fullPath,
	};

	var localFilename = zippedDir + "\\" + _.last(fullPath.split("/"));

	console.log("downloading s3 file " + fullPath + " to " + localFilename);

	var params = {Bucket: logsBucket, Key: fullPath};
	var file = require('fs').createWriteStream(localFilename);

	var reader = s3.getObject(params).createReadStream();
	reader.on('end', function() {
		console.log("dbg: completed downloading a file: " + localFilename);
		cb();
	});
	reader.pipe(file);
}

function doneLoading(err) {
	if (err)
		throw err;

	console.log("done downloading");
	unzipAll();
}

function unzipAll() {
	fs.readdir(zippedDir, function(err, files) {
		if (err)
			throw err;

		var fullFiles = _.filter(_.map(files, function(f) {return zippedDir + "\\" + f}), function(f) { return f.match(/\.zip$/)});	
		async.each(fullFiles, 
			function(f, cb) {
				var cmd = zipExec + " e " + f + " -o" + logDir + " -y";
				console.log("execing " + cmd);
				exec(cmd, function (error, stdout, stderr) {
				  	console.log("unzipping of %s ended. stdout=%s, stderr=%s", f, stdout, stderr);

				  	if (error !== null) {
			     		 console.log("ERROR: unzip exec error: %s", error);
			     		 cb(error);
			    	} else {
				  		cb(); 
				  	}
				  });
			}, 
			function(err) {console.log("done unzipping")});
	});

	//cmd = zipExec + " e " + event.fullPath + " -o" + config.currentConfig().DownloadsUnzipPath + " -y";
}

listLogFilesAtDate('2015-09-11', function(err, files) {
	async.each(_.first(_.map(files, function(f) {return f.Key}), downloadCount), downloadFile, doneLoading);
	});