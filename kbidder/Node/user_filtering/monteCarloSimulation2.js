"use strict"
const rng = require('number-generator')
const Readable = require('stream').Readable
const through = require('through')
const fs = require('fs')
const fastCsv = require('fast-csv')


const simulationMaxLength = 40,
    additionalImpressions = 40,
    additionalImpressionBidRate = 0.2;

module.exports = { loadBidProbabilityDataAsync, monteCarloStream }

function loadBidProbabilityDataAsync(inputFile, callback) {
    var bidProbabilityData = [];
    bidProbabilityData = fs.createReadStream(inputFile, 'utf8')
        .pipe(fastCsv.parse({ headers: true }))
        .pipe(through(function (data) {
            var res = data.requests_in_session,
                wb = data.bids_in_session,
                bidRate = data.bids / data.impressions;
            bidProbabilityData[res] = bidProbabilityData[res] || [];
            bidProbabilityData[res][wb] = { bidRate };
        },
            function () {
                console.log('loading bid probability data finished')
                if (typeof callback == 'function')
                    callback(bidProbabilityData);
                else
                    console.log('no callback provided, exiting')
            })
        )
}

/**
 * a Stream.Readable that emits an object with two random number fields
 * @param {number} [seed=1234] - the seed for the random number generator
 * @param {number} [count=100] - the number of objects emitted before the stream is terminated
 * @returns {Stream.Readable}
 */
function randomNumbers(seed, count) {
    seed = seed || 1234;
    count = count || 100;
    var myRNG = rng.aleaRNGFactory(seed),
        rngPair = new Readable({ objectMode: true }),
        i = count;
    rngPair._read = function () {
        do
            var t = this.push({ rn1: myRNG.uFloat32(), rn2: myRNG.uFloat32() })
        while (t & --i)
        if (!i)
            this.push(null);
    }
    return rngPair;
}


/**
 * a Through stream that reads an object, adds the fields req, uid, nip (next impression probability), isMaxSimulationLength  and emits it
 * @returns {through.ThroughStream}
 */
var reqColumn = function () {
    var prevData;
    return through(function (data) {
        data.req = prevData && prevData.hasAnotherImpression && !prevData.isMaxSimulationLength ? prevData.req + 1 : 1;
        data.uid = prevData && (prevData.uid + (data.req == 1 ? 1 : 0)) || 1;
        data.nip = nextImpressionProbability(data.req);
        data.hasAnotherImpression = data.rn1 < data.nip;
        data.isMaxSimulationLength = false;
        if (data.req == simulationMaxLength) {
            data.isMaxSimulationLength = true;
            data.req += additionalImpressions;
        }
        prevData = data;
        this.queue(data);
    })
}

/**
 * a ThroughStream that reads an object, adds the fields pb (probability of bid), hasBid (0 or 1), wb (cumulative bids for user) and emits it
 * @returns {Through.ThroughStream}
 * @param{Object} bidProbabilityData - a 2D map of bid probabilities per number of requests and history of wb.
 */
var bidColumn = function (bidProbabilityData) {
    var prevData;
    //var wbTotal = 0, wbFiltered = 0, wbUnfiltered = 0;
    return through(function (data) {
        if (!prevData || data.req == 1)
            var prevWb = 0
        else
            prevWb = prevData.wb
        if (data.isMaxSimulationLength) {
            data.pb = additionalImpressionBidRate;
            data.hasBid = additionalImpressions * additionalImpressionBidRate;
        }
        else {
            data.bp = bidProbabilityData[data.req - 1][prevWb].bidRate
            data.hasBid = data.rn2 < data.bp ? 1 : 0;
        }
        data.wb = prevWb + data.hasBid;
        prevData = data;
        this.queue(data);
    })
}

/**
 * a ThroughStream that adds the field isFiltered
 * @param{stateObject} thres - the state that defined the filtering
 * @param{number} thres.res - the number of responses at which perfromance is evaluated
 * @param{number} thres.wb - the maximum wb value to filter, at the given number of requests
 */
var isFilteredColumn = function (thres) {
    var prevData;
    return through(function (data) {
        data.isFiltered = (data.requests === thres.res && data.wb <= thres.wb ||
            data.requests > thres.res && prevData && prevData.isFiltered)
        prevData = data;
        this.queue(data);
    })
}

/**
 * a formula (based on an empirical data set) that approximates the probability of getting another impression from same user 
 * @param{number} x - the number of requests seen from the user
 */
function nextImpressionProbability(x) {
    return 0.921 - 1.5 * Math.exp(-x * 0.79) + x * 0.0008
}

/**
 * takes a bidProbabilityData map and a set of options and returns the last step in a sequence that performs the bidding simulation
 * @param{Object} bidProbabilityData - The two-dimensional bid probability data map
 * @param{Object} options 
 */
function monteCarloStream(bidProbabilityData, options) {
    options = Object.assign({ seed: undefined, count: undefined, thres: { res: undefined, wb: undefined } }, options || {})
    return randomNumbers(options.seed, options.count)
        .pipe(reqColumn())
        .pipe(bidColumn(bidProbabilityData))
        .pipe(isFilteredColumn(options.thres))
}