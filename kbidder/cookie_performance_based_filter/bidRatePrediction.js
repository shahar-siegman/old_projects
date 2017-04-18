"use strict"
const sort = require('sort-stream')
const fastCsv = require('fast-csv')
const through = require('through')
const gb = require('stream-group-by')
const fs = require('fs')
const comp = require('comparer').objectComparison2

const 
    networkLetters = {S: 'sovrn', Y: 'defy', p: 'pubmatic'},
    bid = '_bid',
    bidAboveThres = '_bidAboveThres',
    prediction = '_prediction',
    bidThreshold = 0.05,
    inputFile = './cookie_based_performance1.csv',
    outputFile = './cookie_based_result1.csv'

String.prototype.in = function (arr) { return arr.some(el => this == el) }
Object.values = dict => Object.keys(dict).map(x => dict[x])
const networks = Object.values(networkLetters);
var cumus = {}, lags={};
networks.forEach(function (net) {
    cumus[net + "_cum_bids"] = gb.sum(net + bid)
    cumus[net + "_cum_bids_above"] = gb.sum(net + bidAboveThres)
    lags[net + "_lag_predict"] = gb.lag(net+prediction,1)
})

var a = fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv({ headers: true, delimiter: ';' }))
    .pipe(sort(comp(['placement_id', 'uid'])))
    .pipe(extractNetworkBidLevel('hdbd_json'))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, cumus))
    .pipe(calculatePrediction())
    .pipe(gb.groupBy(['placement_id', 'uid'],true,lags))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log("counters - done") })

/*
function countersPerNetwork(inputField) {
    return function (isCumulative, outputField) {
        return function calculation(keeperObj, data, isLastOfGroup) {
            // init keeperObj
            networks.forEach(function (net) { keeperObj[net] || (keeperObj[net] = { responses: 0, responsesAboveThres: 0 }) })
            var bids = JSON.parse(data[inputField]);
            Object.keys(bids).filter(key => key.split("_").pop() != "rb").forEach(function (key) {  // filter reuse bids data in hdbd_json
                var net = bids[key].net;
                if (typeof net === 'string' && net.in(networks)) {
                    keeperObj[net].responses++;
                    keeperObj[net].responsesAboveThres += (bids[key].cpm && bids[key].cpm > bidThreshold ? 1 : 0)
                }
            })
            var field = JSON.stringify(keeperObj);
            if (!isCumulative && isLastOfGroup) {
                var ret = {}
                ret[outputField] = field
                return ret
            }
            else if (isCumulative) {
                data[outputField] = field;
                return data;
            }
        }
    }
}

function arrangeColumns(JsonColumnName) {
    return through(
        function (data) {
            try {
                var obj = JSON.parse(data[JsonColumnName])
            }
            catch (e) {
                // not a valid JSON, skip parsing
                return
            }
            if (typeof obj == 'object')
                networks.forEach(function (net) {
                    if (obj[net]) {
                        data[net + "_responses"] = obj[net].responses
                        data[net + "_responsesAboveThresh"] = obj[net].responsesAboveThres
                    }
                })
            this.queue(data)
        })
}
*/
function extractNetworkBidLevel(JsonColumnName) {
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

function calculatePrediction() {
    return through(
        function(data) {
            networks.forEach(function(net) {
                data[net+prediction] = parseFloat(data[net+"_cum_bids_above"])/parseFloat(data[net+"_cum_bids"])
            })
        this.queue(data)
        }
    )
}