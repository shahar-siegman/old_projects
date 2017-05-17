"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')


var parseErrors = 0;

/**
 * extract columns for accumulation for a network form hdbd_json field:
 * requests: reqts exists
 * responses: ret = true
 * bids: valid cpm value
 * wins: kb_code matches NetworkLetter
 * revenue: if win, take cpm
 * @param {string} NetworkName - used in fileds name of output record. example: 'sovrn'
 * @param {string} NetworkLetter -the single-character identifying the network. example: 'S'
 */
function parseHdbdForNetwork(NetworkName, NetworkLetter) {
    return through(function (data) {
        var hdbd
        try {
            hdbd = JSON.parse(data.hdbd_json)
        }
        catch (ex) {
            if (typeof errors !== 'undefined') // looking for a 'global' errors variable where the parsing errors can be recorded
                errors.parseErrors = (errors.parseErrors || 0) + 1
            hdbd = {}
        }
        var tag = Object.keys(hdbd).filter(x => x[0] == NetworkLetter)[0],
            networkRecord = hdbd[tag]

        data[NetworkName + '_requests'] = networkRecord && networkRecord.reqts ? 1 : 0
        data[NetworkName + '_responses'] = networkRecord && networkRecord.ret ? 1 : 0
        data[NetworkName + '_bids'] = networkRecord && networkRecord.cpm > 0.01 ? 1 : 0
        data[NetworkName + '_wins'] = networkRecord && data.kb_code[0] == NetworkLetter ? 1 : 0
        data[NetworkName + '_revenue'] = data.kb_code[0] == NetworkLetter ? data.cpm : 0
        data.ord = +data.ord
        this.queue(data)
    })
}

/**
 * runs placement-level aggregations in order to reach 
 * impression-block and revenue-block portion stats
 * for each ordinal and response count
 */
function J() {
    return combiner(
        gb.groupByHyb(['placement_id', 'uid'], false, {
            impressions_in_session: gb.max('ord'),
            wins_in_session: gb.sum('sovrn_wins'),
            bids_in_session: gb.sum('sovrn_bids'),
            revenue_in_session: gb.sum('sovrn_revenue'),
        }),
        gb.groupBy(['placement_id', 'uid'], true, {
            session_cum_wins: gb.sum('sovrn_wins'),
            session_cum_bids: gb.sum('sovrn_bids'),
            session_cum_revenue: gb.sum('sovrn_revenue'),
        }),
        sort(comp(['placement_id', 'ord', 'session_cum_bids'])),
        gb.groupBy(['placement_id', 'ord', 'session_cum_bids'], false, {
            impressions: gb.count(),
            wins: gb.sum('sovrn_wins'),
            bids: gb.sum('sovrn_bids'),
            revenue: gb.sum('sovrn_revenue'),
            impressions_upto_here: gb.sum('ord'),
            wins_upto_here: gb.sum('session_cum_wins'),
            bids_upto_here: gb.sum('session_cum_bids'),
            revenue_upto_here: gb.sum('session_cum_revenue'),
            impressions_all_relevant_sessions: gb.sum('impressions_in_session'),
            wins_all_relevant_sessions: gb.sum('wins_in_session'),
            bids_all_relevant_sessions: gb.sum('bids_in_session'),
            revenue_all_relevant_sessions: gb.sum('revenue_in_session')
        }),
        gb.groupBy(['placement_id', 'ord'], true, {
            impressions_upto_here_cum: gb.sum('impressions_upto_here'),
            wins_upto_here_cum: gb.sum('wins_upto_here'),
            bids_upto_here_cum: gb.sum('bids_upto_here'),
            revenue_upto_here_cum: gb.sum('revenue_upto_here'),
            impressions_all_cum: gb.sum('impressions_all_relevant_sessions'),
            wins_all_cum: gb.sum('wins_all_relevant_sessions'),
            bids_all_cum: gb.sum('bids_all_relevant_sessions'),
            revenue_all_cum: gb.sum('revenue_all_relevant_sessions')
        }),
        gb.groupByHyb(['placement_id'], true, {
            impressions_total: gb.sum('impressions'),
            wins_total: gb.sum('wins'),
            bids_total: gb.sum('bids'),
            revenue_total: gb.sum('revenue'),
        }),
        filter.obj(data =>
            data.impressions_total > 10 &&
            data.bids_total > 5 &&
            data.revenue_total > 0.1 &&
            data.ord <= 100
        ),
        through(function (data) {
            var res = {
                placement_id: data.placement_id,
                ord: data.ord,
                session_cum_bids: data.session_cum_bids,
                impressions_blocked: data.impressions_all_cum - data.impressions_upto_here_cum,
                wins_blocked: data.wins_all_cum - data.wins_upto_here_cum,
                bids_blocked: data.bids_all_cum - data.bids_upto_here_cum,
                revenue_blocked: data.revenue_all_cum - data.revenue_upto_here_cum,
            };
            Object.assign(res, {
                impressions_block_portion: res.impressions_blocked / data.impressions_total,
                wins_blocked_portion: res.wins_blocked / data.wins_total,
                bids_block_portion: res.bids_blocked / data.bids_total,
                revenue_blocked_portion: res.revenue_blocked / data.revenue_total,

                impressions_total: data.impressions_total,
                wins_total: data.wins_total,
                bids_total: data.bids_total,
                revenue_total: data.revenue_total,
            })
            this.queue(res)
        }))
}





function runHJTransform() {
    var h = fs.createReadStream('./data/cookie_sample5_c.csv', 'utf8')
        .pipe(fastCsv.parse({ headers: true }))
        .pipe(parseHdbdForNetwork('sovrn', 'S'))
    var j = J()
    h.pipe(j).pipe(fastCsv.createWriteStream({ headers: true }))
        .pipe(fs.createWriteStream('./data/cookie_sample5_j.csv', 'utf8')).on('finish', function () { console.log('pc sample j - done.') })
}

module.exports = { parseHdbdForNetwork, J}
