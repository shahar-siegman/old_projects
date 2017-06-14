"use strict"
const queryCalculation = require('./cookiesQueryCalculations.js')
const doQuery = require('./redshift_placement_sample_doQuery')
const K = require('./K-bidding_sequence_markov')

const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

var queryTemplate = fs.readFileSync('./queries/single_placement_sample1.sql', 'utf8')
var queryQueue = doQuery.createQueryQueue(8)
var outputFiles = {}, i = 0;
fs.createReadStream('./linear_model_each_placement/Kbidder_top_placements_each_domain_2017_05_30.csv')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        var params = {
            placement_id: data.top_placement_id,
            date: '2017-05-31',
            sampleRatio: Math.min(150000 / data.top_placement_impressions, 1)
        },
            queryParams = queryCalculation(params);
        console.log('queuing ' + queryParams.placement_id)
        this.queue(queryParams);
    }))
    .pipe(doQuery.queryString(queryTemplate, ['placement_id', 'start_time', 'end_time', 'cookie_suffix']))
    .pipe(queryQueue)
    .pipe(through(function (result) {
        var self = this;
        if (result && result.length)
            console.log('streaming ' + result.length + ' rows for ' + result[0].placement_id)
        else
            console.log('empty result encountered')
        result.forEach(function (row) {
            self.queue(row)
        })
    }))
    .pipe(through(function (data) {
        if (!(data.placement_id in outputFiles)) {
            var filename = './linear_model_each_placement/sample_' + data.placement_id + '_K.csv'
            console.log('starting new file: ' + filename)
            outputFiles[data.placement_id] = through();
            outputFiles[data.placement_id]
                .pipe(K.K('sovrn', 'S'))
                .pipe(fastCsv.createWriteStream({ headers: true }))
                .pipe(fs.createWriteStream(filename, 'utf8'))
        }
        data.timestamp = (new Date(data.timestamp)).toISOString().replace('T',' ').slice(0,19)
        outputFiles[data.placement_id].queue(data);
        i++;
        if (i % 50 == 0)
            console.log(i)
    }, function () {
        Object.keys(outputFiles).forEach(function (pid) { outputFiles[pid].queue(null) })
    }

    ))


