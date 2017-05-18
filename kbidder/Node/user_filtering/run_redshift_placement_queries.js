'use strict'
const connections = require('connections')
const fastCsv = require('fast-csv')
const fs = require('fs')
const d3 = require('d3-queue')
const through = require('through')
const format = require('string-format')


/*
fs.createReadStream('queries/sovrn_sampling_rates.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))


var queryParams = { placementId: data.placement_id, date: '2017-05-15', sampleRatio: data.hex2_sample_for_1000_wins }
*/
module.exports = { createQueryQueue, queryString }

function createQueryQueue(parallelCount) {
    var q = d3.queue(parallelCount)
    return through(function (fullQuery) {
        var self = this;
        q.defer(
            function (callback) {
                var rs = connections.kmnRedshift()
                rs.setupDB();
                console.log((new Date).toISOString() + ': ' + fullQuery)
                rs.runQuery(fullQuery, function (err, result) {
                    if (err)
                        console.log('Error: ' + err)
                    else
                        console.log('query successful')
                    if (result && result.rows && result.rows.length)
                        self.queue(result.rows)
                    rs.closeDBConnection();
                    callback();
                })
            })
    }, function () {
        var self = this;
        console.log('done queuing')
        q.await(function (error) {
            if (error)
                throw error;
            console.log((new Date).toISOString() + ': ' + 'done running queued tasks')
            this.queue(null)
        })
    })
}


function queryString(queryTemplate, necessaryKeys) {
    if (necessaryKeys && Array.isArray(necessaryKeys))
        var validate = params =>
            necessaryKeys.forEach(function (key) {
                if (!key in params)
                    return key
            })
    else
        validate = params => null

    return through(function (queryParams) {
        var missing = validate(queryParams)
        if (missing)
            throw new error('key "' + missing + '" is missing in ' + JSON.stringify(queryParams))

        var fullQuery = format(queryTemplate, queryParams)
        this.queue(fullQuery)
    })
}
