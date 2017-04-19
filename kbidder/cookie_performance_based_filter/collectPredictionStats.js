"use strict"

const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const minCumulativeBids = 5,
    networkLetter = 'Y',
    binCount = 10,
    predictionBins = Array.from(new Array(binCount + 1), (x, i) => i / binCount),
    defaultPrediction = 1,
    defaultBlockThreshold = 0.3,
    networkLetters = { S: 'sovrn', Y: 'defy', p: 'pubmatic' }
const network = networkLetters[networkLetter]

var isEligibleForPrediction = (data) => data[network + "_cum_bids"] >= minCumulativeBids;

var mapPredictionToBin = (data) => predictionBins.findIndex(bin => data[network + "_prediction"] <= bin)

function addStartBlockColumn(blockThreshold) {
    return through(function (data) {
        data[network + "_aug_prediction"] = isEligibleForPrediction(data) ? data[network + "_lag_predict"] : defaultPrediction;
        data[network + "_start_block"] = data[network + "_aug_prediction"] < blockThreshold;
        this.queue(data);
    })
}

function addIsNetworkWinColumn() {
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

function addIsBlockedColumn() {
    var a = combiner([addStartBlockColumn(),
    gb.groupBy(['placement_id', 'uid'], true, { isBlocked: gb.sum(network + "_start_block") }),
    through(function (data) {
        data.isBlocked = Math.min(data.isBlocked, 1);
        this.queue(data);
    })
    ]);
    return a;
}

function collectPredictionStats(blockThreshold) {
    blockThreshold || (blockThreshold=defaultBlockThreshold)
    var a = combiner([addStartBlockColumn(blockThreshold),
        addIsBlockedColumn(),
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


