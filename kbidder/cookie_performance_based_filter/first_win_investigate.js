"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

var d = fs.createReadStream('cookie_sample2_c.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) { 
        data.isWin = data.kb_code.length > 0 ? 1 : 0; 
        this.queue(data); }))
    .pipe(gb.groupBy(['placement_id', 'uid', 'sessions'], true, { winsInSession: gb.sum('isWin') }))
    .pipe(filter.obj(function (data) { 
        return data.winsInSession > 0 
    }))
    .pipe(gb.groupBy(['placement_id', 'uid', 'sessions'], false, { 
        firstWin: gb.min('impression_in_session'), 
        wins: gb.sum('isWin'),
        sessionLength: gb.max('impression_in_session') }))

d.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample2_d.csv', 'utf8')).on('finish', function () { console.log('cookie sample d - done') })