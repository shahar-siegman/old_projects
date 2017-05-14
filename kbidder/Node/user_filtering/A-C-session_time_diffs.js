"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')



/** organizes impressions for cookie based filtering:
 * sort and find the time diff of consecutive impressions from the same cookie.
 * classify into 4 categories according to the time gap from the last impression.
 * adds an ordinal of impression for placement-uid
 * adds a "sessions" count (session= activity with gaps of less than 10 minutes)
 * adds an impression counter within session
*/
function A() {
    return combiner(sort(comp(['placement_id', 'uid', 'timestamp'])),
        gb.groupBy(['placement_id', 'uid'], true, { ord: gb.count(), tsLag: gb.lag('timestamp', 1) }),
        through(function timeStampDiff(data) {
            var a = new Date(data.timestamp + 'Z-05'), b = new Date(data.tsLag + 'Z-05'),
                res = {
                    placement_id: data.placement_id,
                    uid: data.uid,
                    timestamp: data.timestamp,
                    ord: data.ord,
                    kb_code: data.kb_code,
                    kb_sold_cpm: data.kb_sold_cpm,
                    cpm: data.cpm,
                    tsDiff: data.tsLag && ((a - b) / 1000),
                    hdbd_json: data.hdbd_json,
                    pc: data.pc
                };
            this.queue(res);
        }),
        through(function timeStampDiffCategory(data) {
            data.tsDiffCategory =
                !data.tsDiff ? null :
                    data.tsDiff <= 60 ? '1 minute' :
                        data.tsDiff <= 600 ? '10 minutes' :
                            data.tsDiff <= 3600 ? '1 hour' :
                                data.tsDiff <= 3600 * 24 ? '24 hours' : 'more than 24 hours';
            data.tsDiffCoarseCategory =
                !data.tsDiff ? null :
                    data.tsDiff <= 600 ? '10 minutes' : 'more than 10 minutes';
            this.queue(data);
        })
    )
}
/*
// save the categorized stream to a file
a.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample_a.csv', 'utf8')).on('finish', function () { console.log('cookie sample a - done') })

// save a histogram of the time-difference categories. 
var b= 
a.pipe(filter.obj(function (data) { return !!data.tsDiffCategory }))
    .pipe(sort(comp(['placement_id', 'uid', 'tsDiffCategory'])))
    .pipe(gb.groupBy(['placement_id', 'uid', 'tsDiffCategory'], false, { cnt: gb.count() }))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample2_b.csv', 'utf8')).on('finish', function () { console.log('cookie sample b - done') })
*/
// count of sessions and of impressions within the session
function C() {
    return combiner(
        sort(comp(['placement_id', 'uid', 'timestamp'])),
        through(function (data) {
            data.tsDiffCoarseCategory = data.tsDiffCoarseCategory || '10 minutes';
            this.queue(data);
        }),
        gb.groupBy([], true, { sessions: gb.countDistinct(['placement_id', 'uid', 'tsDiffCoarseCategory']) }),
        sort(comp(['placement_id', 'uid', 'timestamp'])),
        gb.groupBy(['placement_id', 'uid', 'sessions'], true, { impression_in_session: gb.count() }))
}

function AC() {
    return combiner(A(), C())
}

var queryFile = 'impression_performance_for_cookie_analysis.sql'
inputFile = './data/cookie_sample5.csv',
    outputFile = './data/cookie_sample5_c.csv'

function runACTransform(inputFile, outputFile) {
    var a = fs.createReadStream(inputFile, 'utf8')
        .pipe(fastCsv.parse({ headers: true }))
        .pipe(A())
    var c = a.pipe(C())
    c.pipe(fastCsv.createWriteStream({ headers: true }))
        .pipe(fs.createWriteStream(outputFile, 'utf8'))
        .on('finish', function () {
            console.log('cookie sample c - done')
        })

}

module.exports = { A }
