"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

const network = 'sovrn'

var a = fs.createReadStream('data_for_placement_frontiers.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(filter.obj(x => x.network == network && x.day >= '2017-04-19'))
    .pipe(sort(comp(['sitename', 'domain', 'placement_id', 'day'])))
    .pipe(gb.groupBy(['sitename', 'domain', 'placement_id'], false, { impressions: gb.sum('total_impressions'), revenue: gb.sum('revenue') }))
    .pipe(through(function (data) {
        data.rcpm = 1000 * data.revenue / data.impressions;
        data.rcpmi = -data.rcpm
        this.queue(data);
    }))
    .pipe(sort(comp(['rcpmi'])))
    .pipe(gb.groupBy([], true, { cumImpressions: gb.sum('impressions'), cumRevenue: gb.sum('revenue') }))
    .pipe(gb.groupByHyb([], true, { totalImpressions: gb.sum('impressions'), totalRevenue: gb.sum('revenue') }))
    .pipe(filter.obj(x => x.impressions > 10000))
    .pipe(through(function (data) {
        data.revenuePortion = data.cumRevenue / data.totalRevenue
        data.impsPortion = data.cumImpressions / data.totalImpressions
        data.cumRcpm = 1000*data.cumRevenue/ data.cumImpressions
        delete data.totalRevenue
        delete data.totalImpressions
        delete data.rcpmi
        this.queue(data);
    }))

a.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(network + '_placement_frontier_a.csv', 'utf8')).on('finish', function () { console.log(network + ' placement frontier a - done') })
