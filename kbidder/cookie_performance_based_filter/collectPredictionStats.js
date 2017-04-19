"use strict"

const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const minCumulativeBids = 5,
    binCount = 10,
    predictionBins = Array.from(new Array(binCount + 1), (x, i) => i / binCount),
    defaultPrediction = 1,
    defaultBlockThreshold = 0.3,
    networkLetters = { S: 'sovrn', Y: 'defy', p: 'pubmatic' }

var isEligibleForPrediction = (data,network) => data[network + "_cum_bids"] >= minCumulativeBids;
var mapPredictionToBin = (data,network) => predictionBins.findIndex(bin => data[network + "_prediction"] <= bin)


function getKeyByValue(object, value) {
  return Object.keys(object).find(key => object[key] === value);
}

function addStartBlockColumn(blockThreshold, network) {
    return through(function (data) {
        data[network + "_aug_prediction"] = isEligibleForPrediction(data,network) ? data[network + "_lag_predict"] : defaultPrediction;
        data[network + "_start_block"] = data[network + "_aug_prediction"] < blockThreshold;
        this.queue(data);
    })
}

function addIsNetworkWinColumn(network) {
    if (network=='all')
        return addIsAnyWinColumn()
    var networkLetter = getKeyByValue(networkLetters, network);
    return through(function (data) {
        data.isWin = data.kb_code[0] == networkLetter ? 1 : 0;
        this.queue(data)
    })
}

function addIsAnyWinColumn() {
    return through(function (data) {
        data.isWin = data.kb_code.length > 0 ? 1 : 0;
        this.queue(data)
    })
}

function addIsBlockedColumn(network) {
    var a = combiner(gb.groupBy(['placement_id', 'uid'], true, { isBlocked: gb.sum(network + "_start_block") }),
    through(function (data) {
        data.isBlocked = Math.min(data.isBlocked, 1);
        this.queue(data);
    }));
    return a;
}

function collectPredictionStats(network, blockThreshold) {
    blockThreshold || (blockThreshold=defaultBlockThreshold);
    var a = combiner([addStartBlockColumn(blockThreshold,network),
        addIsBlockedColumn(network),
        sort(comp(['placement_id', 'isBlocked'])),
        gb.groupBy(['placement_id', 'isBlocked'], false, { 
            impressions: gb.count(), 
            bids: gb.sum(network + '_bid'), 
            bidsAbove: gb.sum(network + '_bidAboveThres'),
             wins: gb.sum('isWin') })
    ]);
    return a;
}

module.exports = {
    addIsNetworkWinColumn: addIsNetworkWinColumn,
    addIsAnyWinColumn: addIsAnyWinColumn,
    addIsBlockedColumn: addIsBlockedColumn,
    collectPredictionStats: collectPredictionStats
}


