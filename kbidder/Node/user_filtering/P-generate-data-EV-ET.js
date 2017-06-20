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

var prevData, batch, playProb = {}, successProb = {}, bidValue = {}, horizon = {}

const coeffFile = './data/grouped_by_res_wb_sample2N_coeffs.csv'
var records = JSON.parse(parseCsv('json', fs.readFileSync('./data/grouped_by_res_wb_sample2N_coeffs.csv', 'utf8'), { headers: { included: true } }))


function generateProbabilityFromModelRecords(records) {
    var modelMap = {}, successProb = {}, bidValue = {}
    records.forEach(function (record) {
        modelMap[record.placement_id] = modelMap[record.placement_id] || {};
        modelMap[record.placement_id][record.network] = modelMap[record.placement_id][record.network] || {}
        modelMap[record.placement_id][record.network][record.target] = {
            res: record.res,
            wb: record.wb,
            wb_res_interaction: record.wb_res_interaction,
            intercept: record.ones
        }
    })
    Object.keys(modelMap).forEach(function (placement_id) {
        successProb[placement_id] = {};
        Object.keys(modelMap[placement_id]).forEach(function (network) {
            successProb[placement_id][network] = {};
            var SPcoeffsNotEq = modelMap[placement_id][network].bid_rate_not_eq,
                SPcoeffsEq = modelMap[placement_id][network].bid_rate_not_eq,
                BVcoeffNotEq = modelMap[placement_id][network].bid_value_not_eq,
                BVcoeffEq = modelMap[placement_id][network].bid_value_eq;
            for (var res = 1; res < 50; res++) {
                for (var wb = 0; wb < res; wb++) {
                    successProb[placement_id][network][res] = successProb[placement_id][network][res] || {};
                    successProb[placement_id][network][res][wb] =
                        SPcoeffsNotEq.res * res + SPcoeffsNotEq.wb * wb + SPcoeffsNotEq.wb_res_interaction * wb * res + SPcoeffsNotEq.intercept;
                    bidValue[placement_id][network][res] = bidValue[placement_id][network][res] || {};
                    bidValue[placement_id][network][res][wb] =
                        BVcoeffNotEq.res * res + BVcoeffNotEq.wb * wb + BVcoeffNotEq.wb_res_interaction * wb * res + BVcoeffNotEq.intercept;
                }
                successProb[placement_id][network][res][res] =
                    SPcoeffsEq.res * res + SPcoeffsEq.intercept;
                bidValue[placement_id][network][res][res] =
                    BVcoeffEq.res * res + BVcoeffEq.intercept;
            }
        })
    })
}


var p = fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(sort(comp(['placement_id', 'network', 'res', 'wb'])))
    .pipe(through(function (data) {
        if (data.res == 50) {
            horizon[data.placement_id] = horizon[data.placement_id] || {};
            horizon[data.placement_id][data.network] = horizon[data.placement_id][data.network] || {};
            horizon[data.placement_id][data.network][data.res] = horizon[data.placement_id][data.network][data.res] || {};
            horizon[data.placement_id][data.network][data.res][data.wb] = {
                expectedImps: data.with_response / data.sessions,
                expectedBids: data.with_bid / data.sessions,
                expectedCumBidValue: data.total_bid_value / data.sessions
            }
        }
        this.queue(data);
    }))
    .pipe(gb.groupBy(['name', 'tag_url', 'placement_id', 'network', 'res'], false, { impressions: gb.sum('with_response') }))
    .pipe(gb.groupBy(['name', 'tag_url', 'placement_id', 'network'], true, { lag_impressions: gb.lag('impressions', 1) }))
    .pipe(thorugh(function (data) {
        data.playProb = data.lag_impressions ? data.impressions / data.lag_impressions : 1;
        playProb[data.placement_id] = playProb[data.placement_id] || {};
        playProb[data.placement_id][data.network] = playProb[data.placement_id][data.network] || {};
        playProb[data.placement_id][data.network][data.res] = data.playProb;
        this.queue(data);
    }))
    .pipe(thorugh(function (data) {
        if (prevData && comp(['placement_id', 'network'])(prevData, data)) {
            console.log('calculating for ' + prevData.placement_id + ', ' + prevData.network)
            var result = evTv.recursiveValueCalculation(playProb[prevData.placement_id][prevData.network],
                successProb[prevData.placement_id, prevData.network],
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
                            wb: wb
                        }
                    this.queue(Object.assign(rowHeader, result[res][wb]))
                    rowCount++
                })
            });
            console.log(prevData.placement_id + ', ' + prevData.network + ': ' + rowCount + ' rows created.')
            playProb[prevData.placement_id][prevData.network] = undefined;
            successProb[prevData.placement_id][prevData.network] = undefined;
            bidValue[prevData.placement_id][prevData.network] = undefined;
            horizon[prevData.placement_id][prevData.network] = undefined;
        }
    }))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('pc sample k- done.') })