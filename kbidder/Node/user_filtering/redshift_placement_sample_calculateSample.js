"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const fastCsv = require('fast-csv')
const fs = require('fs')
const quote = require('quote')({ quotes: "'" })


const queryQ = require('./redshift_placement_sample_runQuery')
/**
 * queries a placement and geo (geo: US, all others)
 * runs the K transform
 */

var queryTemplate = fs.readFileSync('./queries/single_placement_sample_with_geo.sql', 'utf8'),
    fileNum = 0,

    queryQueue = queryQ.createQueryQueue(6),
    extractParameters = through(function (data) {
        this.queue({ placement_id: quote(data.placement_id), not: '' })
        this.queue({ placement_id: quote(data.placement_id), not: 'not' })
        console.log('queuing query: ' + quote(data.placement_id))
    }),
    formatter = queryQ.queryString(queryTemplate, ['placement_id', 'not']),
    resultSaver = through(function (queryResult) {
        // this would be an array of objects, need to convert to csv
        queryResult.forEach(function(row) {
            row.timestamp = (new Date(row.timestamp)).toISOString().replace('T',' ').slice(0,19)
        })
        fastCsv.writeToString(queryResult, { headers: true }, function (err, data) {
            var fname = './data/result' + fileNum++ + '.csv'
            console.log('writing ' + queryResult.length + ' rows to ' + fname)
            fs.writeFileSync(fname, data)
        })
    })

fs.createReadStream('./queries/sovrn_sampling_rates.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(extractParameters)
    .pipe(formatter)
    .pipe(queryQueue)
    .pipe(resultSaver)






