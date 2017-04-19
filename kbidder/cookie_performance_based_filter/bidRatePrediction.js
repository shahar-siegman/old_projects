"use strict"
const sort = require('sort-stream')
const fastCsv = require('fast-csv')
const through = require('through')
const gb = require('stream-group-by')
const fs = require('fs')
const comp = require('comparer').objectComparison2
const combiner = require('stream-combiner')
String.prototype.in = function (arr) { return arr.some(el => this == el) }
Object.values = dict => Object.keys(dict).map(x => dict[x])

const
    networkLetters = { S: 'sovrn', Y: 'defy', p: 'pubmatic' },
    bid = '_bid',
    bidAboveThres = '_bidAboveThres',
    prediction = '_prediction'
//bidThreshold = 0.05
//inputFile = './cookie_based_performance1.csv',
//outputFile = './cookie_based_result1.csv'



const networks = Object.values(networkLetters);
var cumus = {}, lags = {};
networks.forEach(function (net) {
    cumus[net + "_cum_bids"] = gb.sum(net + bid)
    cumus[net + "_cum_bids_above"] = gb.sum(net + bidAboveThres)
    lags[net + "_lag_predict"] = gb.lag(net + prediction, 1)
})


function extractNetworkBidLevel(JsonColumnName, bidThreshold) {
    return through(
        function (data) {
            var bids = JSON.parse(data[JsonColumnName]);
            Object.keys(bids).filter(key => key.split("_").pop() != "rb").forEach(function (key) {  // filter reuse bids data in hdbd_json
                var net = networkLetters[key[0]];
                if (typeof net === 'string' && net.in(networks)) {
                    data[net + bid] = 1;
                    data[net + bidAboveThres] = bids[key].cpm && bids[key].cpm > bidThreshold ? 1 : 0
                } else {
                    data[net + bid] = 0;
                    data[net + bidAboveThres] = 0
                }
            })
            networks.forEach(function (net) {
                data[net + bid] = data[net + bid] || 0;
                data[net + bidAboveThres] = data[net + bidAboveThres] || 0;
            })
            this.queue(data);
        }
    )
}

function calculatePredictionStep() {
    return through(
        function (data) {
            networks.forEach(function (net) {
                data[net + prediction] = parseFloat(data[net + "_cum_bids_above"]) / parseFloat(data[net + "_cum_bids"])
            })
            this.queue(data)
        }
    )
}

/*
var a = fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv({ headers: true, delimiter: ';' }))
    .pipe(sort(comp(['placement_id', 'uid'])))
    .pipe(extractNetworkBidLevel('hdbd_json'))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, cumus))
    .pipe(calculatePredictionStep())
    .pipe(gb.groupBy(['placement_id', 'uid'], true, lags))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log("counters - done") })
*/
function calculatePrediction(bidThreshold) {
    if (isNaN(bidThreshold))
        throw new onerror('invalid bid threshold: '+ bidThreshold)
    var a = combiner([sort(comp(['placement_id', 'uid'])),
    extractNetworkBidLevel('hdbd_json',bidThreshold),
    gb.groupBy(['placement_id', 'uid'], true, cumus),
    calculatePredictionStep(),
    gb.groupBy(['placement_id', 'uid'], true, lags)]);

    return a;
}

module.exports = calculatePrediction