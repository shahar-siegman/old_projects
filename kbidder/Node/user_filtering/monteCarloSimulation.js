"use strict"
const through = require('through')
const fastCsv = require('fast-csv')
const fs = require('fs')
const comp = require('comparer').objectComparison2
const streamify = require('stream-array')
const gb = require('stream-group-by')

const simulationMaxLength = 40,
    additionalImpressions = 40,
    additionalImpressionBidRate = 0.2;

var inputFile = './data/cookie_sample13K_sovrn.csv',
    gameCount = 100,
    filterThres = { res: 25, wb: 0 };


module.exports = monteCarloSimulation;

/** 
 * @callback simulationResultCallback
 * @param {Object} playResult
 * @param {number} playResult.res - responses
 * @param {number} playResult.wb - with bid
 * @param {boolean} playResult.isFiltered - if user was filtered
 * 
*/
/**
 * Loads bid probability data from a file (a sample that was processed with K-bidding_sequence_markov.js) 
 * Then calls playMonteCarlo
 * @param {simulationResultCallback}
 * */
function monteCarloSimulation(callback) {
    var bidProbabilityData = [];
    fs.createReadStream(inputFile, 'utf8')
        .pipe(fastCsv.parse({ headers: true }))
        .pipe(through(function (data) {
            var res = data.requests_in_session,
                wb = data.bids_in_session,
                bidRate = data.bids / data.impressions;
            bidProbabilityData[res] = bidProbabilityData[res] || [];
            bidProbabilityData[res][wb] = { bidRate };
        },
            function () {
                console.log('monte carlo simulation - loading bid probability data finished')
                var simResult = playMonteCarlo(gameCount, bidProbabilityData)
                calculateStats(simResult, function (stats) {
                    if (typeof callback == 'function')
                        callback(simResult, stats)
                })
            }))
}

function playMonteCarlo(gameCount, bidProbabilityData) {
    gameCount || (gameCount = 1000);
    var simResult = new Array(gameCount),
        playResult;
    for (var i = 0; i < gameCount; i++) {
        playResult = playSingle(bidProbabilityData, filterThres);
        simResult[i] = playResult;
    }
    return simResult;
}


function playSingle(bidProbabilityData, filterThreshold) {
    var hasAnotherImpression = true,
        res = 0,
        wb = 0,
        isFiltered = false;

    if (filterThreshold.res < simulationMaxLength) {
        for (; hasAnotherImpression && res < filterThreshold.res; res++) {
            var bidRate = bidProbabilityData[res][wb].bidRate,
                hasBid = Math.random() < bidRate ? 1 : 0,
                hasAnotherImpression = Math.random() < nextImpressionProbability(res + 1);
            wb += hasBid;
        }
        isFiltered = (res = filterThreshold.res && wb <= filterThreshold.wb);
    }
    for (; hasAnotherImpression && res < simulationMaxLength; res++) {
        var bidRate = bidProbabilityData[res][wb].bidRate,
            hasBid = Math.random() < bidRate ? 1 : 0,
            hasAnotherImpression = Math.random() < nextImpressionProbability(res + 1);
        wb += hasBid;
    }

    if (res == simulationMaxLength) {
        res += additionalImpressions;
        wb += additionalImpressions * additionalImpressionBidRate;
    }
    return { res, wb, isFiltered }
}


function nextImpressionProbability(x) {
    return 0.921 - 1.5 * Math.exp(-x * 0.79) + x * 0.0008
}

function calculateStats(originalSimResult, callback) {
    var simResult = new Array(originalSimResult.length),
        stats = [];
    for (var i = 0; i < simResult.length; i++)
        simResult[i] = originalSimResult[i];
    simResult.sort(comp(['isFiltered']))
    return streamify(simResult).pipe(gb.groupBy(['isFiltered'], false, {
        runs: gb.count(),
        impressions: gb.sum('res'),
        bids: gb.sum('wb')
    })).pipe(through(function (data) {
        stats.push(data);
    },
        function () {
            if (typeof callback == 'function') {
                callback(stats)
            }
        }))
}
