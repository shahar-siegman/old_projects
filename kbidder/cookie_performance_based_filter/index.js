const collect = require('./collectPredictionStats.js')
const fastCsv = require('fast-csv')
const fs = require('fs')
const bidRatePrediction = require('./bidRatePrediction.js')



function establishBidRatePrediction(inputFile, outputFile, cb) {
    fs.createReadStream(inputFile, 'utf8')
        .pipe(fastCsv({ headers: true, delimiter: ";" }))
        .pipe(bidRatePrediction(0.05))
        .pipe(fastCsv.createWriteStream({ headers: true }))
        .pipe(fs.createWriteStream(outputFile, 'utf8'))
        .on('finish', function () {
            console.log('establish BidRate Prediction - done writing to ' + outputFile);
            if (typeof cb == 'function')
                cb()
        })
}

function collectPredictionStats(inputFile, outputFile, cb) {
    fs.createReadStream(inputFile)
        .pipe(fastCsv({ headers: true }))
        .pipe(collect.addIsNetworkWinColumn())
        .pipe(collect.collectPredictionStats())
        .pipe(fastCsv.createWriteStream({ headers: true }))
        .pipe(fs.createWriteStream(outputFile, 'utf8'))
        .on('finish', function () {
            console.log('collect Prediction Stats - done writing to ' + outputFile)
            if (typeof cb == 'function')
                cb()
        })
}

establishBidRatePrediction('./cookie_based_performance2.csv', 'preformance_with_bidrate_prediction2.csv'
, function() {
    collectPredictionStats('preformance_with_bidrate_prediction2.csv', 'predictionStats2.csv')
})