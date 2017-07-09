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
const markov = require('./O-markov-library')

const playProbFile = './data/cookie_based_session_length_sample1_playProbs.csv',
    inputFile = './data/grouped_by_res_wb_sample3N_coeffs.csv',
    outputFile = './data/grouped_by_res_wb_sample3Q.csv',
    horizonRes = 50;

/**
 * @returns {number} the "dot product" of the two objects, by multiplying and summing matching keys 
 * @param {object} t1 - Map of numbers
 * @param {object} t2 - Map of numbers, contains the fields that t1 contains
 */ 
var dotProduct = function (t1, t2) {
    var t1Keys = Object.keys(t1)
    return t1Keys.reduce(function (sum, key) {
        return sum + t1[key] * t2[key]
    }, 0)
}

/**
 * @returns {number} the sum of all values in the "leaves" 
 * @param {*} obj - a multi-level nested object. all leaves should be cast-able to number
 * @param {String[]} keysForSum - the keys to take into account at the top level. subsequent levels have all their keys taken.
 */
var sumMapRecursive = function (obj, keysForSum) {
    return keysForSum.reduce(function (sum, key) {
        if (typeof obj[key] == 'object')
            return sum + sumMapRecursive(obj[key], Object.keys(obj[key]))
        return sum + obj[key]
    }, 0)
}

/**
 * @returns {number[]} - array of numbers starting with a ending with b (both integers)
 * @param {number} a - start of range
 * @param {number} b - end of range
 */
var range = function (a, b) {
    var ret = new Array(b - a + 1)
    for (var i = 0; i < ret.length; i++)
        ret[i] = i + a;
    return ret;
}


var playProbRecords = JSON.parse(parseCsv('json', fs.readFileSync(playProbFile, 'utf8'), { headers: { included: true } })),
    playProb = arrayToLookup(playProbRecords, ['placement_id', 'impression'], (record) => record.play_prob);
Object.keys(playProb).forEach(function (placement_id) {
    playProb[placement_id][0] = 1;
})



fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(sort(comp(['tag_url', 'placement_id', 'network'])))
    .pipe(passModelsAsBatch())
    .pipe(modelsToTransitionMap(playProb, horizonRes))
    .pipe(characetristicCurve(1, 10, horizonRes))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('generate EV-TV Q - done.') })

/**
 * @returns a through element that collects input rows belonging to a placement_id and network, 
 * with different "target" fields, and queues them as an object with "target" field and the model linear 
 * coefficients in the data
 */
function passModelsAsBatch() {
    var prevData = []
    var placementNetworkCompare = comp(['placement_id', 'network']);

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
    // passModelsAsBatch return statement
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

/**
 * 
 * @param {*} playProb 
 * @param {*} horizonRes 
 */
function modelsToTransitionMap(playProb, horizonRes) {
    return through(function (models) {
        var successProb = function (res, wb) {
            if (wb < 0 || res < 0 || res > horizonRes)
                var r = 0;
            else if (wb > res)
                r = 1;
            else if (wb == res)
                r = models.bid_rate_eq.res * res + models.bid_rate_eq.intercept
            else
                r = models.bid_rate_not_eq.res * res
                    + models.bid_rate_not_eq.wb * wb
                    + models.bid_rate_not_eq.wb_res_interaction * wb * res
                    + models.bid_rate_not_eq.bid_rate_so_far * wb / res
                    + models.bid_rate_not_eq.intercept;
            return Math.max(Math.min(r, 1), 0)
        }
        var bidValue = function (res, wb) {
            if (wb < 0 || wb > res || res < 0 || res > horizonRes)
                return 0;
            if (wb == res)
                var r = models.bid_value_eq.res * res + models.bid_value_eq.intercept
            else
                r = models.bid_value_not_eq.res * res
                    + models.bid_value_not_eq.wb * wb
                    + models.bid_value_not_eq.wb_res_interaction * wb * res
                    + models.bid_value_not_eq.bid_rate_so_far * wb / res
                    + models.bid_value_not_eq.intercept;
            return Math.max(r, 0)
        }
        var transitionMap = markov.constructUniversalTransitionMap(playProb[models.placement_id], successProb, bidValue, horizonRes);
        this.queue({
            placement_id: models.placement_id,
            network: models.network,
            utm: transitionMap
        })
    })
}

function characetristicCurve(minResForCalc, maxResForCalc, horizonRes) {
    return through(function (data) { //universal transition map
        var probAndValue = markov.pathImpsAndValueSingleState({ res: 0, wb: 0 }, data.utm, horizonRes, true),
            probMap = probAndValue.probMap,
            valueMap = probAndValue.valueMap;

        var soFar = markov.pathImpsAndValueSingleState({ res: 0, wb: 0 }, data.utm, maxResForCalc),
            impsAndValuePerWb = {},
            totalImpsAndValue = { impressions: 0, value: 0 },
            totalNormFactor = 0;
        var soFar2Value = valueMap[0][0] - dotProduct(probMap[maxResForCalc + 1], valueMap[maxResForCalc + 1])
        var soFar2Impressions = sumMapRecursive(probMap, range(1, maxResForCalc + 1))

        for (var res = minResForCalc; res <= maxResForCalc; res++) {
            for (var wb = 0; wb <= res; wb++) {
                impsAndValuePerWb[wb] = markov.pathImpsAndValueSingleState({ res: res, wb: wb }, data.utm, horizonRes)
                totalImpsAndValue.impressions += probMap[res][wb] * impsAndValuePerWb[wb].impressions;
                totalImpsAndValue.value += probMap[res][wb] * impsAndValuePerWb[wb].value
                totalNormFactor += probMap[res][wb];
            }
            var allowed = totalImpsAndValue,
                allowedNormFactor = totalNormFactor,
                blocked = { impressions: 0, value: 0 },
                blockedNormFactor = 0;
            for (wb = 0; wb <= res; wb++) {
                var delta = {
                    impressions: probMap[res][wb] * impsAndValuePerWb[wb].impressions,
                    value: probMap[res][wb] * impsAndValuePerWb[wb].value,
                    norm: probMap[res][wb]
                }
                blocked.impressions += delta.impressions
                blocked.value += delta.value
                blockedNormFactor += delta.norm
                allowed.impressions -= delta.impressions
                allowed.value -= delta.value
                allowedNormFactor -= delta.norm
                this.queue({
                    placement_id: data.placement_id,
                    network: data.network,
                    res: res,
                    wb: wb,
                    probMap: probMap[res][wb],
                    blockedNormFactor: blockedNormFactor,
                    blocked_impressions: blocked.impressions,
                    blocked_value: blocked.value,
                    allowedNormFactor: allowedNormFactor,
                    allowed_impressions: soFar.impressions + allowed.impressions,
                    allowed_value: soFar.value + allowed.value
                })

            }
        }
    }
    )
}

