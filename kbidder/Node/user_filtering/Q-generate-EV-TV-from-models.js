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

var placementNetworkCompare = comp(['placement_id', 'network']),
    prevData = [],
    modelCoeffs,
    modelsSoFar;

function extractCoeffs(x) {
    return {
        res: +x.res,
        wb: +x.wb,
        wb_res_interaction: +x.wb_res_interaction,
        bid_rate_so_far: +x.bid_rate_so_far,
        intercept: +x.ones
    }
}

fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        if (prevData.length && placementNetworkCompare(prevData[0], data)) {
            if (prevData.length < 4)
                console.log(`${data.placement_id}, ${data.network}: found ${modelsSoFar} models, skipping`)
            else {
                var toPush = arrayToLookup(prevData, ['target'], extractCoeffs)
                toPush.placement_id = prevData[0].placement_id;
                toPush.network = prevData[0].network
                this.queue(toPush)
                prevData = []
            }
        }
        prevData.push(data);
    }))
    .pipe(expandValueModel())
    .pipe(addPlayProbColumn())

function expandValueModel() {
    return through(function (models) {
        for (var res = 1; res <= horizonRes; res++) {
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