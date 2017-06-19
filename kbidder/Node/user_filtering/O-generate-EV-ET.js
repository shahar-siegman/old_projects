"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const runRScript = require('./RScriptWrapper')

function recursiveValueCalculation(playProb, successProb, horizon) {
    /*
    playProb: [playProb[0], playProb[1],... , playProb[50]]
    successProb: { 0: [succesProb0_0], 1: [successProb1_0, successProb1_1]}
    horizon: { 50: { 0: { expectedImps: eImps, expectedBids: eBids exptedValue: eValue }}}
    */
    var maxRes = Object.keys(horizon)[0],
        result = { maxRes: horizon[maxRes] }
    for (var res = maxRes - 1; res >= 0; res--) {
        for (var wb = 0; wb <= res; wb++) {
            var currentData = {
                // zero is hard coded since we assume the playProb is the same for all wb
                expectedImps: res + playProb[res] * (1 + result[res + 1][0].expectedImps),
                expectedBids: wb + successProb[res][wb] +
                playProb[res] * ((1 - successProb[res][wb]) * result[res + 1][wb].expectedBids +
                    successProb[res][wb] * result[res + 1][wb + 1]),
                exptedValue: 
            }
        }
    }
} 