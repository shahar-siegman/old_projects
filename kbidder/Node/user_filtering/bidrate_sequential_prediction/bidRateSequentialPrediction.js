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

module.exports = calculatePrediction

const networks = Object.values(networkLetters);
var cumus = {}, lags = {};
networks.concat("all").forEach(function (net) {
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

            data["all" + bid] = networks.reduce((p, net) => Math.min(p + data[net + bid], 1), 0)
            data["all" + bidAboveThres] = networks.reduce((p, net) => Math.min(p + data[net + bidAboveThres], 1), 0)
            this.queue(data);
        }
    )
}

function calculatePredictionStep() {
    return through(
        function (data) {
            networks.concat("all").forEach(function (net) {
                data[net + prediction] = parseFloat(data[net + "_cum_bids_above"]) / parseFloat(data[net + "_cum_bids"])
            })
            this.queue(data)
        }
    )
}
/**
* verifies that bid rate is roughly consistent with historical bid rate
* bid rate prediction is simply the historical bid rate up to one impression ago
*/
function calculatePrediction(bidThreshold) {
    if (isNaN(bidThreshold))
        throw new error('invalid bid threshold: ' + bidThreshold)
    var a = combiner(
        [sort(comp(['placement_id', 'uid'])),
        extractNetworkBidLevel('hdbd_json', bidThreshold),
        gb.groupBy(['placement_id', 'uid'], true, cumus),
        calculatePredictionStep(),
        gb.groupBy(['placement_id', 'uid'], true, lags)]);

    return a;
}

