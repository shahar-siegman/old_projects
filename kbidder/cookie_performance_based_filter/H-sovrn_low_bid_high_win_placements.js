"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('./mySortTransform')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const shallowCopy = require('shallow-copy')

var parseErrors = 0;
var h = fs.createReadStream('./data/cookie_sample5_c.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        var hdbd
        try {
            hdbd = JSON.parse(data.hdbd_json)
        }
        catch (ex) {
            parseErrors++
        }
        var sovrnKey = Object.keys(hdbd).filter(x => x[0] == 'S')[0],
            sovrnRecord = hdbd[sovrnKey]

        data.sovrn_requests = sovrnRecord && sovrnRecord.reqts ? 1 : 0
        data.sovrn_responses = sovrnRecord && sovrnRecord.ret ? 1 : 0
        data.sovrn_bids = sovrnRecord && sovrnRecord.cpm > 0.01 ? 1 : 0
        data.sovrn_wins = sovrnRecord && data.kb_code[0] == 'S' ? 1 : 0
        data.ord = +data.ord
        this.queue(data)
    }))
/*
var i = h
    .pipe(gb.groupBy(['placement_id', 'uid'], false, {
        session_length: gb.max('ord'),
        sovrn_requests: gb.sum('sovrn_requests'),
        sovrn_responses: gb.sum('sovrn_responses'),
        sovrn_bids: gb.sum('sovrn_bids'),
        sovrn_wins: gb.sum('sovrn_wins')
    }))
    .pipe(filter.obj(data => data.session_length > 3))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./data/cookie_sample5_i.csv', 'utf8')).on('finish', function () { console.log('pc sample i - done. parse errors: ' + parseErrors) })
*/
var j = h
    .pipe(through(function (data) {
        data.sovrn_revenue = data.kb_code[0] == 'S' ? data.cpm : 0
        this.queue(data);
    }))
    .pipe(gb.groupByHyb(['placement_id', 'uid'], false, {
        impressions_in_session: gb.max('ord'),
        revenue_in_session: gb.sum('sovrn_revenue'),
        bids_in_session: gb.sum('sovrn_bids')
    }))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, {
        session_cum_revenue: gb.sum('sovrn_revenue'),
        session_cum_bids: gb.sum('sovrn_bids')
    }))
    .pipe(through(function (data) {
        data.cum_bids_reverese = -data.session_cum_bids;
        this.queue(data);
    }))
    .pipe(sort(comp(['ord', 'session_cum_bids'])))
    .pipe(gb.groupBy(['ord', 'session_cum_bids'], false, {
        impressions: gb.count(),
        bids: gb.sum('sovrn_bids'),
        revenue: gb.sum('sovrn_revenue'),
        impressions_upto_here: gb.sum('ord'),
        bids_upto_here: gb.sum('session_cum_bids'),
        revenue_upto_here: gb.sum('session_cum_revenue'),
        impressions_all_relevant_sessions: gb.sum('impressions_in_session'),
        bids_all_relevant_sessions: gb.sum('bids_in_session'),
        revenue_all_relevant_sessions: gb.sum('revenue_in_session')
    }))
    .pipe(gb.groupBy(['ord'], true, {
        impressions_upto_here_cum: gb.sum('impressions_upto_here'),
        bids_upto_here_cum: gb.sum('bids_upto_here'),
        revenue_upto_here_cum: gb.sum('revenue_upto_here'),
        impressions_all_cum: gb.sum('impressions_all_relevant_sessions'),
        bids_all_cum: gb.sum('bids_all_relevant_sessions'),
        revenue_all_cum: gb.sum('revenue_all_relevant_sessions')
    }))
    .pipe(gb.groupBy([], true, {
        impressions_running_total: gb.sum('impressions'),
        bids_running_total: gb.sum('bids'),
        revenue_running_total: gb.sum('revenue'),
    }))

/*
h.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./data/cookie_sample5_h.csv', 'utf8')).on('finish', function () { console.log('pc sample h - done.') })
*/
j.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./data/cookie_sample5_j.csv', 'utf8')).on('finish', function () { console.log('pc sample j - done.') })
/*
var k = h
    .pipe(through(function (data) {
        data.sovrn_revenue = data.kb_code[0] == 'S' ? data.cpm : 0
        this.queue(data);
    }))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, {
        session_cum_revenue: gb.sum('sovrn_revenue'),
        session_cum_bids: gb.sum('sovrn_bids')
    }))
    .pipe(sort(comp(['ord', 'session_cum_bids'])))
    
    .pipe(gb.groupBy(['ord', 'session_cum_bids'], false, {
        impressions: gb.count(),
        bids: gb.sum('sovrn_bids'),
        revenue: gb.sum('sovrn_revenue')
    }))


k.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./data/cookie_sample5_k.csv', 'utf8')).on('finish', function () { console.log('pc sample k - done.') })
*/
