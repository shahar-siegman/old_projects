"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

/*
// get the ordinal of the first win and the length of every chain with win
// in order to find the cumulative distribution function of the wins in the session
// result: uniform distribution except an 'anomaly' in 15% of impressions that are in the last event in the session
var d = fs.createReadStream('cookie_sample2_c.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        data.isWin = data.kb_code.length > 0 ? 1 : 0;
        this.queue(data);
    }))
    .pipe(gb.groupBy(['placement_id', 'uid', 'sessions'], true, { winsInSession: gb.sum('isWin') }))
    .pipe(filter.obj(function (data) {
        return data.winsInSession > 0
    }))
    .pipe(gb.groupBy(['placement_id', 'uid', 'sessions'], false, {
        firstWin: gb.min('impression_in_session'),
        wins: gb.sum('isWin'),
        sessionLength: gb.max('impression_in_session')
    }))

d.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample2_d.csv', 'utf8')).on('finish', function () { console.log('cookie sample d - done') })


// histogram of session lengths
var e = fs.createReadStream('cookie_sample2_c.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(gb.groupBy(['placement_id', 'uid', 'sessions'], false, { impressionsCount: gb.count() }))
    .pipe(sort(comp(['placement_id', 'impressionsCount'])))
    .pipe(gb.groupBy(['placement_id', 'impressionsCount'], false, { sessionWithThisManyImpressions: gb.count() }))

e.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample2_e.csv', 'utf8')).on('finish', function () { console.log('cookie sample e - done') })


// get the rcpm, and the portion of the overall revenue, by the impression ordinal (per placement)
var f = fs.createReadStream('cookie_sample3_c.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) { data.impression_in_session = +data.impression_in_session; this.queue(data) })) // convert to number
    .pipe(sort(comp(['placement_id', 'impression_in_session', 'uid'])))
    .pipe(gb.groupBy(['placement_id', 'impression_in_session'], false, { cpmOfCount: gb.sum('cpm'), impressions: gb.count() }))
    .pipe(gb.groupBy(['placement_id'], true, { cumulativeCpmOfCount: gb.sum('cpmOfCount') }))
    .pipe(gb.groupByHyb(['placement_id'], true, { cpmOfPlacement: gb.sum('cpmOfCount') }))
    .pipe(through(function (data) {
        data.cpmOfCount = data.cpmOfCount / 1000;
        data.cumulativeCpmOfCount = data.cumulativeCpmOfCount / 1000;
        data.cpmOfPlacement = data.cpmOfPlacement / 1000;
        data.relativeCpmOfPlacement = data.cumulativeCpmOfCount / data.cpmOfPlacement;
        data.rcpm = 1000 * data.cpmOfCount / data.impressions;
        this.queue(data);
    }))

f.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample3_f.csv', 'utf8')).on('finish', function () { console.log('cookie sample f - done') })
*/

var g = fs.createReadStream('cookie_sample3_c.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) { data.impression_in_session = +data.impression_in_session; this.queue(data) })) // convert to number
    .pipe(gb.groupByHyb(['placement_id', 'uid', 'sessions'], true, { impressions_in_session: gb.count() }))
    .pipe(through(function (data) {
        data.impressions_in_session = Math.min(data.impressions_in_session, 4);
        data.isWin = data.kb_code.length > 0;
        this.queue(data);
    }))
    .pipe(filter.obj(function (data) { return data.impression_in_session == 1 }))
    .pipe(sort(comp(['placement_id', 'impressions_in_session', 'sessions'])))
    .pipe(gb.groupBy(['placement_id', 'impressions_in_session'], false, { cost: gb.sum('kb_sold_cpm'), revenue: gb.sum('cpm'), impressions: gb.count(), wins: gb.sum('isWin') }))
    .pipe(through(function (data) {
        var r = (x,d) => Math.round(x*Math.pow(10,d))/Math.pow(10,d)
        data.cost = r(data.cost / 1000,4);
        data.revenue = r(data.revenue / 1000,4);
        data.rcpm = r(1000 * data.cost / data.impressions,6);
        data.ecpm = r(1000 * data.cost / data.wins,4);
        data.margin = r(1 - data.cost/data.revenue,3);
        this.queue(data);
    }))

g.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('cookie_sample3_g.csv', 'utf8')).on('finish', function () { console.log('cookie sample g - done') })
