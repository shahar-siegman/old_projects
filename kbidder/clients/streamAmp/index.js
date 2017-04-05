"use strict"
const fastCsv = require('fast-csv')
const gb = require('stream-group-by')
const fs = require('fs')

const inputFile = './data_for_latency_impact.csv'

var winsByRests = gb.groupBy(['placement_id', 'round_rests', 'round_bid'], false, { availBids: gb.sum('available_bids'), totalWins: gb.sum('win') })


fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv({ headers: true }))
    .pipe(winsByRests)
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./latency_impact1.csv', 'utf8'))
    .on('finish', done)



function done() { console.log('done') }
