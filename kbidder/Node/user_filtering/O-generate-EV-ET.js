"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

module.exports = { recursiveValueCalculation }
/**
 * Calcualtes value at each res, wb, backwards from the "horizon" (res=50)
 * @param {*} playProb 
 * @param {*} successProb 
 * @param {*} bidValue 
 * @param {*} horizon 
 */
function recursiveValueCalculation(playProb, successProb, bidValue, horizon) {
    /*
    playProb: [playProb[0], playProb[1],... , playProb[50]]
    successProb: { 0: [succesProb0_0], 1: [successProb1_0, successProb1_1]}
    horizon: { 50: { 0: { expectedImps: eImps, expectedBids: eBids expectedValue: eValue }}}
    */
    var maxRes = Object.keys(horizon)[0],
        result = {};
    result[maxRes] = horizon[maxRes]
    for (var res = maxRes - 1; res > 0; res--) {
        for (var wb = 0; wb <= res; wb++) {
            var currentData = {
                // expected imps: probability of an extra impression
                // + horizon impressions in landing state
                // note the .expectedImps is the same for all wb's 
                expectedImps: 1 + playProb[res] * result[res + 1][0].expectedImps,
                // expected bids: probability of an extra bid
                // + horizon impressions in the landing states weighted by the landing state probability 
                expectedBids: successProb[res][wb] + playProb[res] * (
                    successProb[res][wb] * result[res + 1][wb + 1].expectedBids + (1 - successProb[res][wb]) * result[res + 1][wb].expectedBids),
                // expected value: same principle
                expectedValue: successProb[res][wb] * bidValue[res][wb] + playProb[res] * (
                    (1 - successProb[res][wb]) * result[res + 1][wb].expectedValue
                    + successProb[res][wb] * result[res + 1][wb + 1].expectedValue)
            };
            /* var pretty = {}
            Object.keys(currentData).forEach(function (key) { pretty[key] = Math.round(currentData[key] * 1000) / 1000 })
            console.log(JSON.stringify([res, wb]) + ': ' + JSON.stringify(pretty)) */
            result[res] = result[res] || {};
            result[res][wb] = currentData;
        }
    }
    return result;
}

/*
function universalProbabilityCalculation(playProb, successProb) {
    var maxRes = Math.max(...Object.keys(playProb)),
        result = { 0: { 0: 1 } };
    for (var res = 1; res <= maxRes; res++) {
        for (var wb = 0; wb <= res; wb++) {
            result[res][wb] = result[res - 1][wb] * playProb[res - 1] * (1 - successProb[res - 1][wb])
            if (wb > 0)
                result[res][wb] += result[res - 1][wb - 1] * playProb[res - 1] * successProb[res - 1][wb - 1]
        }
    }
    return result;
}

*/