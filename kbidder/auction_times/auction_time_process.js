var fs = require('fs');
var moment = require('moment');
var csvWriter = require('csv-write-stream');
var writer = csvWriter();
var client = {
  user: "master",
  db: "logs",
  password: "ntxyrNtxyr77",
  port: 5439,
  host: 'kmnspark.crc6oizgxxw8.us-east-1.redshift.amazonaws.com'
};
var rsQueryFile = 'auction_time_query.sql';

var binSize=25;
var placement_id = {master: '83d6f1934c618a6b7f30f17f1671d794', replaceWith: 'ba700e6107b084243c2d03850d45efd9'};
var queryDate = {master: '2016-07-24', replaceWith: '2016-07-26'};

var query =  fs.readFileSync(rsQueryFile, "utf8");
if (!placement_id.replaceWith) placement_id.replaceWith = placement_id.master;
if (placement_id.replaceWith && placement_id.replaceWith != placement_id.master) {
  query=query.replace(placement_id.master, placement_id.replaceWith);
}
if (!queryDate.replaceWith) queryDate.replaceWith = queryDate.master;
if (queryDate.replaceWith && queryDate.replaceWith != queryDate.master) {
  query=query.replace(queryDate.master, queryDate.replaceWith);
}

var outFileName = 'auctionTimeHist' +'.csv';
var a=fs.createWriteStream(outFileName);
writer.pipe(a);

var rssql = require('redshift-sql')(client);
console.log(moment().format('HH:mm:ss')+': Querying RedShift');
console.log(query);

rssql(query, function cb(err, result) {
  if (err) {
    return console.error(err);
  }
  var nrows= result.rows.length;
  console.log(moment().format('HH:mm:ss')+': ' +nrows + ' rows returned.');
  var h={};
  
  for (var i=0; i<nrows; i++) 
  {
      var row = result.rows[i];
      var startTime= Number(row.accepted_bid_ts);
      var endTime= Number(row.rejected_bid_ts);

      var timings={
        startTimeFrac:  Math.ceil(startTime/binSize)*binSize-startTime,
        endTimeFrac:  endTime-Math.floor(endTime/binSize)*binSize,
        startTimeBin: Math.floor(startTime/binSize)*binSize,
        endTimeBin:  Math.floor(endTime/binSize)*binSize
      };
      var denom = nrows*(endTime-startTime);
      for (var k=timings.startTimeBin; k<=timings.endTimeBin; k+=binSize) 
      {
          // calculating the histogram of the estimated probability 
          // for a middle bin, it is equal binSize/(endTime-startTime) which represents the integral of a uniform pdf over a segment of length binSize 
          // for a border bin, is is equal the part of the segment that overlaps the bin
          var contrib;
          if (k==timings.startTimeBin) {
            contrib=timings.startTimeFrac;
          }
          else if (k==timings.endTimeBin) {
            contrib=timings.endTimeFrac;
          } else {
            contrib=binSize;
          }
          if (h[k]) {
            h[k]+=contrib/denom;
          } else {
            h[k]=contrib/denom;
          }
      }
  }
  for (var x in h) {
      writer.write({placement_id: placement_id.replaceWith,
        date: queryDate.replaceWith,
        latency_milliseconds: x, 
        latency_value: h[x]});
  }
  writer.end();
  a.end();
});
