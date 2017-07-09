"use strict"
const fs = require('fs')
const parseCsv = require('parse-csv')
const fastCsv = require('fast-csv')
const streamify = require('stream-array')


var successProb = {}, bidValue = {}, i = 0


Object.prototype.dot = function (t2) {
    var t1 = this;
    console.log(JSON.stringify(t1))
    console.log(JSON.stringify(t2))
    var t1Keys = Object.keys(t1)
    return t1Keys.reduce(function (sum, key) {
        return sum + t1[key] * t2[key]
    }, 0)
}

var sumMapRecursive = function (obj, keysForSum) {
    return keysForSum.reduce(function (sum, key) {
        if (typeof obj[key] == 'object')
            return sum + sumMapRecursive(obj[key], Object.keys(obj[key]))
        return sum + obj[key]
    },0)
}


test()

function test1() {
    var records = JSON.parse(parseCsv('json', fs.readFileSync('./data/grouped_by_res_wb_sample2N_coeffs.csv', 'utf8'), { headers: { included: true } }))
    generateProbabilityFromModelRecords(records)
    var flatData = iterateBidProbAndValue()
    streamify(flatData).pipe(fastCsv.format({ headers: true })).pipe(fs.createWriteStream('bidProbTest.csv', 'utf8')).on('finish', function () { console.log('test parse done') })
}

function test2() {
    var obj1 = { 0: 4, 2: 5.5, 3: 10, 6: 15 }
    var obj2 = { 0: 1, 2: 2, 3: 3, 6: 4 } // 4 + 11+ 30+60 =105
    console.log('dot product: ' + obj1.dot(obj2) )
}

function test() {
    var obj = {a: 1, b:2 , c:{a:5, b:7, c:8}, d: {a:9, t:15}}
    console.log(sumMapRecursive(obj,['a']))
    console.log(sumMapRecursive(obj,['a','c']))
    console.log(sumMapRecursive(obj,['a','b','c','d']))
}


function generateProbabilityFromModelRecords(records) {
    var modelMap = {}
    records.forEach(function (record) {
        modelMap[record.placement_id] = modelMap[record.placement_id] || {};
        modelMap[record.placement_id][record.network] = modelMap[record.placement_id][record.network] || {}
        modelMap[record.placement_id][record.network][record.target] = {
            res: +record.res,
            wb: +record.wb,
            wb_res_interaction: +record.wb_res_interaction,
            bid_rate_so_far: +record.bid_rate_so_far,
            intercept: +record.ones
        }
    })
    Object.keys(modelMap).forEach(function (placement_id) {
        successProb[placement_id] = {};
        bidValue[placement_id] = {};
        Object.keys(modelMap[placement_id]).forEach(function (network) {
            successProb[placement_id][network] = {};
            bidValue[placement_id][network] = {};
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
            for (var res = 1; res < 50; res++) {
                for (var wb = 0; wb < res; wb++) {
                    successProb[placement_id][network][res] = successProb[placement_id][network][res] || {};
                    successProb[placement_id][network][res][wb] =
                        SPcoeffsNotEq.res * res
                        + SPcoeffsNotEq.wb * wb
                        + SPcoeffsNotEq.wb_res_interaction * wb * res
                        + SPcoeffsNotEq.bid_rate_so_far * wb / res
                        + SPcoeffsNotEq.intercept;
                    bidValue[placement_id][network][res] = bidValue[placement_id][network][res] || {};
                    bidValue[placement_id][network][res][wb] =
                        BVcoeffNotEq.res * res
                        + BVcoeffNotEq.wb * wb
                        + BVcoeffNotEq.wb_res_interaction * wb * res
                        + BVcoeffNotEq.bid_rate_so_far * wb / res
                        + BVcoeffNotEq.intercept;
                }
                successProb[placement_id][network][res][res] =
                    SPcoeffsEq.res * res + SPcoeffsEq.intercept;
                bidValue[placement_id][network][res][res] =
                    BVcoeffEq.res * res + BVcoeffEq.intercept;
            }
        })
    })
}

function iterateBidProbAndValue() {
    var result = []
    Object.keys(bidValue).forEach(function (placement_id) {
        Object.keys(bidValue[placement_id]).forEach(function (network) {
            Object.keys(bidValue[placement_id][network]).forEach(function (res) {
                Object.keys(bidValue[placement_id][network][res]).forEach(function (wb) {
                    var row = {
                        placement_id: placement_id,
                        network: network,
                        res: res,
                        wb: wb,
                        bidValue: bidValue[placement_id][network][res][wb]
                    }
                    try {
                        row.successProb = successProb[placement_id][network][res][wb]
                    } catch (err) {
                        row.successProb = null;
                    }
                    console.log(i++)
                    result.push(row)
                })
            })
        })
    })
    return result;
}
