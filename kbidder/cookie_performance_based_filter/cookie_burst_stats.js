"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

// find the time diff of consecutive impressions from the same cookie.
// classify into 4 categories according to the time gap from the last impression.
var a = fs.createReadStream('cookie_sample2.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(sort(comp(['placement_id', 'uid', 'timestamp'])))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, { ord: gb.count(), tsLag: gb.lag('timestamp', 1) }))
    .pipe(through(function timeStampDiff(data) {
        var a = new Date(data.timestamp + 'Z-05'), b = new Date(data.tsLag + 'Z-05'),
            res = {
                placement_id: data.placement_id,
                uid: data.uid,
                timestamp: data.timestamp,
                ord: data.ord,
                kb_code: data.kb_code,
                tsDiff: data.tsLag && ((a - b) / 1000)
            };
        //data.tsDiff = (b - a) / 1000;
        this.queue(res);
    }))
    .pipe(through(function timeStampDiffCategory(data) {
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
    }))
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
var c =
    a.pipe(sort(comp(['placement_id', 'uid', 'timestamp'])))
        .pipe(through(function(data) { 
            data.tsDiffCoarseCategory = data.tsDiffCoarseCategory || '10 minutes'; 
            this.queue(data); 
        }))
        .pipe(gb.groupBy([], true, { sessions: gb.countDistinct(['placement_id', 'uid', 'tsDiffCoarseCategory']) }))
        .pipe(sort(comp(['placement_id', 'uid', 'timestamp'])))
        .pipe(gb.groupBy(['placement_id', 'uid', 'sessions'], true, { impression_in_session: gb.count() }))


c.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample2_c.csv', 'utf8')).on('finish', function () { console.log('cookie sample c - done') })

