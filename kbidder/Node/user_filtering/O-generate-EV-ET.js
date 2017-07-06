"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

module.exports = {
    universalProbabilityCalculation,
    valueAheadCalculation,
    valueSoFarCalculation,
    cumulativeImpsAndValueForLastStaters,
    allowedAndBlockedImpressions,
}
/**
 * Calcualtes value at each res, wb, backwards from the "horizon" (res=50)
 * @param {*} playProb 
 * @param {*} successProb 
 * @param {*} bidValue 
 * @param {*} horizon 
 * @returns {object}  - object contains expectedImps, expectedBids, expectedValue for each [res][wb] double-index
 */
function valueAheadCalculation(playProb, successProb, bidValue, maxRes) {
    /*
    playProb: [playProb[0], playProb[1],... , playProb[50]]
    successProb: { 0: [succesProb0_0], 1: [successProb1_0, successProb1_1]}
    horizon: { 50: { 0: { expectedImps: eImps, expectedBids: eBids expectedValue: eValue }}}
    */
    var result = {};
    result[maxRes] = {}
    for (var i = 0; i <= maxRes; i++)
        result[maxRes][i] = {
            expectedImps: playProb[maxRes],
            expectedBids: successProb[maxRes][i] * playProb[maxRes],
            expectedValue: bidValue[maxRes][i] * playProb[maxRes]
        };
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
             if (Object.keys(currentData).some(key => typeof currentData[key] != 'number' ))
                throw new Error(`valueAheadCalculation encountered non-number`)
        }
    }
    return result;
}

function valueSoFarCalculation(universalProbMap, successProb, bidValue, maxRes) {
    var valueMap = { 0: { 0: 0 } }
    for (var res = 1; res <= maxRes; res++) {
        valueMap[res] = {}
        for (var wb = 0; wb <= res; wb++) {
            // un-normalized prob of getting here from (res-1,wb-1)
            valueMap[res][wb] = 0;
            var prob1 = wb > 0 ? successProb[res - 1][wb - 1] * universalProbMap[res - 1][wb - 1] : 0,
                prob2 = wb < res ? (1 - successProb[res - 1][wb]) * universalProbMap[res - 1][wb] : 0;
            prob1 > 0 && (valueMap[res][wb] += valueMap[res - 1][wb - 1] * (prob1 / (prob1 + prob2)));
            prob2 > 0 && (valueMap[res][wb] += valueMap[res - 1][wb] * (prob2 / (prob1 + prob2)))
            valueMap[res][wb] += bidValue[res][wb] * successProb[res][wb]
        }
    }
    return valueMap;
}

function universalProbabilityCalculation(playProb, successProb, maxRes) {
    var probMap = { 0: { 0: 1 } },
        sumProbs = 0;
    //playProb[0] = 1;
    var currentResLevelProbIndex = 1;
    for (var res = 1; res <= maxRes; res++) {
        probMap[res] = {}
        for (var wb = 0; wb <= res; wb++) {
            probMap[res][wb] = playProb[res] * (
                (wb < res ? probMap[res - 1][wb] * (1 - successProb[res - 1][wb]) : 0) +
                (wb > 0 ? probMap[res - 1][wb - 1] * successProb[res - 1][wb - 1] : 0)
            )
            sumProbs += probMap[res][wb]
        }
    }
    var recip = 1 / sumProbs
    for (var res = 1; res <= maxRes; res++)
        for (var wb = 0; wb <= res; wb++)
            probMap[res][wb] *= recip
    return probMap;
}

function cumulativeImpsAndValueForLastStaters(valueSoFar, playProb, maxRes) {
    // normalize probMap to res
    var sumValue = 0, sumImps = 0, result = {};
    for (var res = 1; res < maxRes; res++) {
        for (var wb = 0; wb <= res; wb++) {
            sumValue += valueSoFar[res][wb] * (1 - playProb[res])
        }
        sumImps += res * (1 - playProb[res])
        result[res] = { value: sumValue, impressions: sumImps };
        if (typeof sumImps != 'number' || typeof sumValue != 'number' || sumImps <0 || sumValue <0)
            throw new Error(`cumulative encountered non-number or negative: res= ${res}, wb=${wb}, sumImps= ${sumImps}, sumValue=${sumValue}`)
    }
    return result;
}

function allowedAndBlockedImpressions(cumImpsAndValueIfLastState, valueAhead, maxRes) {
    var sumValue = 0, sumImps = 0, result = {};
    for (var res = 1; res < maxRes; res++) {
        result[res] = {};
        var blockedImpressionsAhead = 0,
            blockedValueAhead = 0,
            allowedImpressionsAhead = Object.keys(valueAhead[res]).reduce((sum, wb) => sum + valueAhead[res][wb].expectedImps, 0),
            allowedValueAhead = Object.keys(valueAhead[res]).reduce((sum, wb) => sum + valueAhead[res][wb].expectedValue, 0)
        for (var wb = 0; wb <= res; wb++) {
            blockedImpressionsAhead += valueAhead[res][wb].expectedImps
            blockedValueAhead += valueAhead[res][wb].expectedValue
            allowedImpressionsAhead -= valueAhead[res][wb].expectedImps
            allowedValueAhead -= valueAhead[res][wb].expectedValue
            result[res][wb] = {
                allowedImpressions: cumImpsAndValueIfLastState[res].impressions + allowedImpressionsAhead,
                allowedValue: cumImpsAndValueIfLastState[res].value + allowedValueAhead,
                blockedImpressions: blockedImpressionsAhead,
                blockedValue: blockedValueAhead
            }
            
            if (Object.keys(result[res][wb]).some(key => typeof result[res][wb][key] != 'number' ))
                throw new Error(`allowed and blocked encountered non-number`)

        }
    }
    return result;
}
