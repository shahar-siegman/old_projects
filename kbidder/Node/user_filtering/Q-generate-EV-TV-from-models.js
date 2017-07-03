"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const parseCsv = require('parse-csv')
const fs = require('fs')
const filter = require('stream-filter')
const evTv = require('./O-generate-EV-ET')
const arrayToLookup = require('./P-generate-data-EV-ET').arrayToLookup

const playProbFile = './data/cookie_based_session_length_sample1_playProbs.csv',
    inputFile = './data/grouped_by_res_wb_sample3N_coeffs.csv',
    outputFile = './data/grouped_by_res_wb_sample3Q.csv',
    horizonRes = 50;

var placementNetworkCompare = comp(['placement_id', 'network']),
    prevData = [],
    prevData2 = [],
    modelCoeffs,
    modelsSoFar;

var playProbRecords = JSON.parse(parseCsv('json', fs.readFileSync(playProbFile, 'utf8'), { headers: { included: true } })),
    playProbMap = arrayToLookup(playProbRecords, ['placement_id', 'impression'], function (record) {
        return {
            play_prob: record.play_prob,
            cum_relative_imps: record.cum_relative_imps
        }
    });







fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(sort(comp(['tag_url', 'placement_id', 'network'])))
    .pipe(passModelsAsBatch())
    .pipe(expandValueModel())
    .pipe(streamGenerateEvEt())
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('generate EV-TV Q - done.') })

function passModelsAsBatch() {
    var prevData = []
    var extractCoeffs = function (x) {
        return {
            res: +x.res,
            wb: +x.wb,
            wb_res_interaction: +x.wb_res_interaction,
            bid_rate_so_far: +x.bid_rate_so_far,
            intercept: +x.ones
        }
    }
    var handleEndOfBatch = function (queue) {
        if (prevData.length < 4)
            console.log(`${prevData[0].placement_id}, ${prevData[0].network}: found ${prevData.length} models, skipping`)
        else {
            var toPush = arrayToLookup(prevData, ['target'], extractCoeffs)
            toPush.placement_id = prevData[0].placement_id;
            toPush.network = prevData[0].network
            queue(toPush)
        }
    }
    return through(function (data) {
        if (prevData.length && placementNetworkCompare(prevData[0], data)) {
            handleEndOfBatch(this.queue)
            prevData = []
        }
        prevData.push(data);
    },
        function () {
            handleEndOfBatch(this.queue)
        })
}

function expandValueModel() {
    return through(function (models) {
        for (var res = 0; res <= horizonRes; res++) {
            for (var wb = 0; wb < res; wb++) {
                var successProb =
                    models.bid_rate_not_eq.res * res
                    + models.bid_rate_not_eq.wb * wb
                    + models.bid_rate_not_eq.wb_res_interaction * wb * res
                    + models.bid_rate_not_eq.bid_rate_so_far * wb / res
                    + models.bid_rate_not_eq.intercept;
                successProb = Math.max(Math.min(successProb, 1), 0)
                var bidValue =
                    models.bid_value_not_eq.res * res
                    + models.bid_value_not_eq.wb * wb
                    + models.bid_value_not_eq.wb_res_interaction * wb * res
                    + models.bid_value_not_eq.bid_rate_so_far * wb / res
                    + models.bid_value_not_eq.intercept;
                bidValue = Math.max(bidValue, 0)

                this.queue({
                    placement_id: models.placement_id,
                    network: models.network,
                    res: res,
                    wb: wb,
                    successProb: successProb,
                    bidValue: bidValue
                })
            }
            this.queue({
                placement_id: models.placement_id,
                network: models.network,
                res: res,
                wb: res,
                successProb: Math.max(Math.min(models.bid_rate_eq.res * res + models.bid_rate_eq.intercept, 1), 0),
                bidValue: Math.max(models.bid_value_eq.res * res + models.bid_value_eq.intercept, 0)
            })
        }
    })
}

function streamGenerateEvEt() {
    var prevData = [];
    var handleEndOfBatch = function (queue) {
        var successProb = {}, bidValue = {}, playProb = {}, relativeTraffic = {};
        prevData.forEach(function (record) {
            successProb[record.res] = successProb[record.res] || {};
            successProb[record.res][record.wb] = record.successProb;
            bidValue[record.res] = bidValue[record.res] || {};
            bidValue[record.res][record.wb] = record.bidValue;
        })
        Object.keys(playProbMap[prevData[0].placement_id]).forEach(function (res) {
            playProb[res] = playProbMap[prevData[0].placement_id][res].play_prob
            relativeTraffic[res] = playProbMap[prevData[0].placement_id][res].cum_relative_imps
        })
        var valueAheadResult = evTv.valueAheadCalculation(playProb, successProb, bidValue, horizonRes),
            frequenceyResult = evTv.universalProbabilityCalculation(playProb,successProb, horizonRes),
            valueSoFarResult = evTv.valueSoFarCalculation(frequenceyResult,successProb,bidValue,horizonRes);
        for (var res = 1; res <= horizonRes; res++)
            for (var wb = 0; wb <= res; wb++)
                queue({
                    placement_id: prevData[0].placement_id,
                    network: prevData[0].network,
                    res: res,
                    wb: wb,
                    expectedImps: valueAheadResult[res][wb].expectedImps,
                    expectedBids: valueAheadResult[res][wb].expectedBids,
                    expectedValue: valueAheadResult[res][wb].expectedValue,
                    relativeTrafficForRes: relativeTraffic[res],
                    frequency: frequenceyResult[res][wb],
                    valueSoFar: valueSoFarResult[res][wb]
                })
        prevData = [];
    }
    return through(function (data) {
        if (prevData.length && placementNetworkCompare(prevData[0], data)) {
            handleEndOfBatch(this.queue)
        }
        prevData.push(data)
    }, function () { handleEndOfBatch(this.queue) })
}