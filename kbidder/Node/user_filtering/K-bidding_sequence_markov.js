"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const H = require('./H-sovrn_low_bid_high_win_placements.js')

// var network = 'sovrn', networkLetter = 'S'

/** calculates, per placement_id, the probability of 
 * getting a bid conditional on the number of prior requests and prior bids 
 * per user
 * input data minimum requirements: placement_id, uid, timestamp, hdbd_json
 */

function K(network,networkLetter) {
    return combiner(
        H.parseHdbdForNetwork(network, networkLetter),
        sort(comp(['placement_id', 'uid', 'timestamp'])),
        filter.obj(data => data[network + '_requests'] == 1),
        gb.groupBy(['placement_id', 'uid'], true, {
            requests_in_session: gb.sum(network + '_requests'),
            bids_in_session: gb.sum(network + '_bids')
        }),
        filter.obj(data => data.requests_in_session <= 20),
        through(function (data) {
            data.requests_in_session = data.requests_in_session - 1;
            data.bids_in_session = data.bids_in_session - data[network + '_bids']
            this.queue(data)
        }),
        sort(comp(['placement_id', 'requests_in_session', 'bids_in_session'])),
        gb.groupBy(['placement_id', 'requests_in_session', 'bids_in_session'], false, {
            impressions: gb.count(),
            bids: gb.sum(network + '_bids'),
            wins: gb.sum(network + '_wins'),
            revenue: gb.sum(network + '_revenue')
        }))
}


function runKTransform() {
    var k =
        fs.createReadStream('./data/cookie_sample_12.csv', 'utf8')
            .pipe(fastCsv.parse({ headers: true }))
            .pipe(K())
            .pipe(fastCsv.createWriteStream({ headers: true }))
            .pipe(fs.createWriteStream('./data/cookie_sample12_k_sovrn.csv', 'utf8')).on('finish', function () { console.log('pc sample k- done.') })
}

module.exports = { K, runKTransform }
