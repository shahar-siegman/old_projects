'use strict'
const connections = require('connections')
const fastCsv = require('fast-csv')
const fs = require('fs')
const d3 = require('d3-queue')
const through = require('through')
const queryString = require('./placement_query_string')

var q = d3.queue(1)


fs.createReadStream('queries/sovrn_sampling_rates.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        var queryParams = { placementId: data.placement_id, date: '2017-05-11', sampleRatio: data.hex2_sample_for_1000_wins }
        console.log('queuing query: ' + JSON.stringify(queryParams))
        q.defer(
            function (params, callback) {
                var rs = connections.kmnRedshift(),
                    fullQuery = queryString(params)
                rs.setupDB();
                console.log(fullQuery)
                rs.runQuery(fullQuery, function (err, result) {
                    if (err)
                        console.log('Error: ' + err)
                    else
                        console.log('query successful')
                    rs.closeDBConnection();
                    callback();
                })
            },
            queryParams
        )
    })).on('finish', function () {
        console.log('done queuing')
        q.await(function (error) {
            if (error)
                throw error;
            console.log('done running queued tasks')
        })
    })

