"use strict"
const mcs2 = require('./monteCarloSimulation2')
const fastCsv = require('fast-csv')
const fs = require('fs')

var inputFile = './data/cookie_sample13K_sovrn.csv',
    outputFile = './data/simulation13_sovrn.csv'
// var  gameCount = 1000,  filterThres = { res: 8, wb: 0 };

function runSimulation() {
    mcs2.loadBidProbabilityDataAsync(inputFile, function (bidProbabilityData) {
        mcs2.monteCarloStream(bidProbabilityData, { seed: 1234, count: 1000, thres: { res: 10, wb: 0 } })
            .pipe(fastCsv.createWriteStream({ headers: true }))
            .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('mc simulation - done.') })
    })
}

runSimulation();

