"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
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
        requests_in_session: gb.sum('sovrn_requests'),
        bids_in_session: gb.sum('sovrn_bids'),
        revenue_in_session: gb.sum('sovrn_revenue'),
    }))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, {
        session_cum_requests: gb.sum('sovrn_requests'),
        session_cum_bids: gb.sum('sovrn_bids'),
        session_cum_revenue: gb.sum('sovrn_revenue'),
    }))
    .pipe(sort(comp(['ord', 'session_cum_bids'])))
    .pipe(gb.groupBy(['ord', 'session_cum_bids'], false, {
        impressions: gb.count(),
        requests: gb.sum('sovrn_requests'),
        bids: gb.sum('sovrn_bids'),
        revenue: gb.sum('sovrn_revenue'),
        impressions_upto_here: gb.sum('ord'),
        requests_upto_here: gb.sum('session_cum_requests'),
        bids_upto_here: gb.sum('session_cum_bids'),
        revenue_upto_here: gb.sum('session_cum_revenue'),
        impressions_all_relevant_sessions: gb.sum('impressions_in_session'),
        requests_all_relevant_sessions: gb.sum('requests_in_session'),
        bids_all_relevant_sessions: gb.sum('bids_in_session'),
        revenue_all_relevant_sessions: gb.sum('revenue_in_session')
    }))
    .pipe(gb.groupBy(['ord'], true, {
        impressions_upto_here_cum: gb.sum('impressions_upto_here'),
        requests_upto_here_cum: gb.sum('requests_upto_here'),
        bids_upto_here_cum: gb.sum('bids_upto_here'),
        revenue_upto_here_cum: gb.sum('revenue_upto_here'),
        impressions_all_cum: gb.sum('impressions_all_relevant_sessions'),
        requests_all_cum: gb.sum('requests_all_relevant_sessions'),
        bids_all_cum: gb.sum('bids_all_relevant_sessions'),
        revenue_all_cum: gb.sum('revenue_all_relevant_sessions')
    }))
    .pipe(gb.groupByHyb([], true, {
        impressions_total: gb.sum('impressions'),
        requests_total: gb.sum('requests'),
        bids_total: gb.sum('bids'),
        revenue_total: gb.sum('revenue'),
    }))
    .pipe(through(function(data) {
        data.impressions_blocked = data.impressions_all_cum - data.impressions_upto_here_cum
        data.requests_blocked = data.requests_all_cum - data.requests_upto_here_cum
        data.bids_blocked = data.bids_all_cum - data.bids_upto_here_cum 
        data.revenue_blocked = data.revenue_all_cum - data.revenue_upto_here_cum

        data.impressions_block_portion = data.impressions_blocked / data.impressions_total
        data.requests_blocked_portion = data.requests_blocked/ data.requests_total
        data.bids_block_portion = data.bids_blocked/ data.bids_total
        data.revenue_blocked_portion = data.revenue_blocked / data.revenue_total
        this.queue(data)
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
