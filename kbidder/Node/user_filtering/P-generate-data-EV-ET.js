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

const rawDataFile = './data/grouped_by_res_wb_sample3.csv',
    coeffFile = './data/grouped_by_res_wb_sample3N_coeffs.csv',
    outputFile = './data/grouped_by_res_wb_sample3P.csv',
    horizonRes = 50;

/**
 * @callback tr1
 * @param {Object} record
 * @returns {Object}
 */

/** 
* Converts an array of records (i.e. flat objects which share the same field names) to a nested map,
* based on a list of keys (field names). Each key combination is assumed to be unique in the dataset.
* The records at the leaves of the returned object are produced by
* applying the `transform` function to the original record 
* @param {Object[]} records 
* @param {string[]} keys 
* @param {tr1} transform 
* @returns {Object}
*/
function arrayToLookup(records, keys, transform) {
    var lookup = {}
    if (!keys.every(x => x && typeof x == 'string'))
        throw new error('keys must be an array of nonempty strings')
    if (typeof transform != 'function')
        throw new error('transform must be a function')
    records.forEach(function (record) {
        var nexter = lookup;
        keys.forEach(function (key, index) {
            if (index == keys.length - 1)
                nexter[record[key]] = transform(record)
            else {
                nexter[record[key]] = nexter[record[key]] || {};
                nexter = nexter[record[key]];
            }
        })
    })
    return lookup;
}

/**
 * Uses records (the rows produced by transformation N), each containing the linear coefficients of one model type for one placement and network.
 * Stores (in the form of a nested map) the values predicted by each model for each network, placement, res and wb
 * @param {Object[]} records - Array containing linear models for Bid Value and "Success" (probability of bid).
 */
function applyLinearModelsToAllResWbInRange(records) {
    // converts the records into a more accessible structure of nested keys
    var modelMap = arrayToLookup(records, ['placement_id', 'network', 'target'], function (x) {
        return {
            res: +x.res,
            wb: +x.wb,
            wb_res_interaction: +x.wb_res_interaction,
            bid_rate_so_far: +x.bid_rate_so_far,
            intercept: +x.ones
        }
    })
    // iterate the placements, networks and models in `modelmap`
    Object.keys(modelMap).forEach(function (placement_id) {
        successProb[placement_id] = {};
        bidValue[placement_id] = {};
        Object.keys(modelMap[placement_id]).forEach(function (network) {
            successProb[placement_id][network] = {};
            bidValue[placement_id][network] = {};
            // fill in defaults for missing models
            var SPcoeffsNotEq = modelMap[placement_id][network].bid_rate_not_eq,
                SPcoeffsEq = modelMap[placement_id][network].bid_rate_eq || {
                    res: null,
                    wb: null,
                    wb_res_interaction: null,
                    bid_rate_so_far: null,
                    intercept: null
                },
                BVcoeffNotEq = modelMap[placement_id][network].bid_value_not_eq || {
                    res: null,
                    wb: null,
                    wb_res_interaction: null,
                    bid_rate_so_far: null,
                    intercept: null
                },
                BVcoeffEq = modelMap[placement_id][network].bid_value_eq || {
                    res: null,
                    wb: null,
                    wb_res_interaction: null,
                    bid_rate_so_far: null,
                    intercept: null
                };
            // main loop: apply linear models for each res and wb
            for (var res = 1; res <= horizonRes; res++) {
                for (var wb = 0; wb < res; wb++) {
                    successProb[placement_id][network][res] = successProb[placement_id][network][res] || {};
                    successProb[placement_id][network][res][wb] =
                        SPcoeffsNotEq.res * res
                        + SPcoeffsNotEq.wb * wb
                        + SPcoeffsNotEq.wb_res_interaction * wb * res
                        + SPcoeffsNotEq.bid_rate_so_far * wb / res
                        + SPcoeffsNotEq.intercept;
                    successProb[placement_id][network][res][wb] = Math.max(Math.min(successProb[placement_id][network][res][wb], 1), 0)
                    bidValue[placement_id][network][res] = bidValue[placement_id][network][res] || {};
                    bidValue[placement_id][network][res][wb] =
                        BVcoeffNotEq.res * res
                        + BVcoeffNotEq.wb * wb
                        + BVcoeffNotEq.wb_res_interaction * wb * res
                        + BVcoeffNotEq.bid_rate_so_far * wb / res
                        + BVcoeffNotEq.intercept;
                }
                successProb[placement_id][network][res][res] =
                    Math.max(Math.min(SPcoeffsEq.res * res + SPcoeffsEq.intercept, 1), 0);
                bidValue[placement_id][network][res][res] =
                    Math.max(BVcoeffEq.res * res + BVcoeffEq.intercept, 0);
            }
        })
    })
    return { successProb, bidValue }
}


function runP() {
    var playProb = {},
        successProb = {},
        bidValue = {},
        horizon = {},
        preHorizonResponses = 0,
        preHorizonBids = 0,
        prevData, batch;

    var records = JSON.parse(parseCsv('json', fs.readFileSync(coeffFile, 'utf8'), { headers: { included: true } }))
    var placementNetworkValueModel = applyLinearModelsToAllResWbInRange(records)
    var p = fs.createReadStream(rawDataFile, 'utf8')
        .pipe(fastCsv.parse({ headers: true }))
        .pipe(through(function (data) {
            data.res = +data.res;
            data.wb = +data.wb;
            this.queue(data);
        }))
        .pipe(sort(comp(['placement_id', 'network', 'res', 'wb'])))
        .pipe(gb.groupBy(['placement_id', 'network'], true, { lag_pid: gb.lag('placement_id', 1) }))
        .pipe(through(function (data) {
            if (!data.lag_pid) // new placement-network pair
                preHorizonResponses = 0;
            if (data.res >= horizonRes - 5 && data.res < horizonRes) {
                preHorizonResponses += +data.with_response
            }
            if (data.res == horizonRes) {
                var preHorizonValid = preHorizonResponses > 1000,
                    denominator = preHorizonValid ? (preHorizonResponses / 5) : data.sessions;
                horizon[data.placement_id] = horizon[data.placement_id] || {};
                horizon[data.placement_id][data.network] = horizon[data.placement_id][data.network] || {};
                horizon[data.placement_id][data.network][data.res] = horizon[data.placement_id][data.network][data.res] || {};
                // replicate the horizon data to each wb level since it appears only once in the input
                for (var i = 0; i <= horizonRes; i++) {
                    var expectedImps = data.with_response / denominator
                    horizon[data.placement_id][data.network][data.res][i] = {
                        expectedImps: expectedImps,
                        expectedBids: successProb[data.placement_id][data.network][data.res][i] * expectedImps,
                        expectedValue: bidValue[data.placement_id][data.network][data.res][i] * expectedImps,
                        preHorizonValid: preHorizonValid
                    }
                }
            }
            this.queue(data);
        }))
        .pipe(gb.groupBy(['name', 'tag_url', 'placement_id', 'network', 'res'], false, { impressions: gb.sum('with_response') }))
        .pipe(gb.groupBy(['name', 'tag_url', 'placement_id', 'network'], true, { lag_impressions: gb.lag('impressions', 1) }))
        .pipe(through(function (data) {
            data.playProb = data.lag_impressions ? Math.min(data.impressions / data.lag_impressions, 1) : 1; //lag is missing in 1st entry
            playProb[data.placement_id] = playProb[data.placement_id] || {};
            playProb[data.placement_id][data.network] = playProb[data.placement_id][data.network] || {};
            playProb[data.placement_id][data.network][data.res] = data.playProb;
            this.queue(data);
        }))
        .pipe(through(function (data) {
            recursiveValueCalculationStep(data, this)
        }, function () {
            recursiveValueCalculationStep({ placement_id: null, network: null }, this)
        }))
        .pipe(fastCsv.createWriteStream({ headers: true }))
        .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('pc generate data P - done.') })

    /**
     * collects records (ordered by placement id and network).
     * when finishes receiveing all rows for a placement-network pair, calls `evTv`
     * for calculating the expected value of a user in that placement 
     * based on the data for that placement and network in the global data structures
     * `playProb, successProb, bidValue, horizon`
     * @param {Object} data - a record to process (from a stream) 
     * @param {Object} streamObj - the Through object (for queuing the result into)
     */
    function recursiveValueCalculationStep(data, streamObj) {
        if (prevData && comp(['placement_id', 'network'])(prevData, data)) {
            if (prevData.placement_id in bidValue && prevData.network in bidValue[prevData.placement_id]) {
                console.log('calculating for ' + prevData.placement_id + ', ' + prevData.network)
                console.log(`successProb: ${Object.keys(successProb).length}, in placement: ${Object.keys(successProb[prevData.placement_id])} `)
                var result = evTv.recursiveValueCalculation(playProb[prevData.placement_id][prevData.network],
                    successProb[prevData.placement_id][prevData.network],
                    bidValue[prevData.placement_id][prevData.network],
                    horizon[prevData.placement_id][prevData.network]),
                    allRes = Object.keys(result),
                    rowCount = 0;
                allRes.forEach(function (res) {
                    var allWb = Object.keys(result[res]);
                    allWb.forEach(function (wb) {
                        var rowHeader =
                            {
                                placement_id: prevData.placement_id,
                                network: prevData.network,
                                res: res,
                                wb: wb,
                                preHorizonValid: horizon[prevData.placement_id][prevData.network][horizonRes][0].preHorizonValid
                            }
                        streamObj.queue(Object.assign(rowHeader, result[res][wb]))
                        rowCount++
                    })
                });
                console.log(prevData.placement_id + ', ' + prevData.network + ': ' + rowCount + ' rows created.')
                // "free" the memory and feed the GC monster ;)
                playProb[prevData.placement_id][prevData.network] = undefined;
                successProb[prevData.placement_id][prevData.network] = undefined;
                bidValue[prevData.placement_id][prevData.network] = undefined;
                horizon[prevData.placement_id][prevData.network] = undefined;
            }
            else
                console.log(`filtered: ${prevData.placement_id}, ${prevData.network}`)
        }
        prevData = data;
    }
}