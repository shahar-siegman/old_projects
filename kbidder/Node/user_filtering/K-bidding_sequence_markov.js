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

//

/** calculates, per placement_id, the probability of 
 * getting a bid conditional on the number of prior requests and prior bids 
 * per user
 * input data minimum requirements: placement_id, uid, timestamp, hdbd_json, kb_code, cpm
 */

function K(network,networkLetter, options) {
    var placementId = options && options.aggregate_placementId=== false ? []: ['placement_id']    // ===
         
    return combiner(
        H.parseHdbdForNetwork(network, networkLetter),
        sort(comp(['placement_id', 'uid', 'timestamp'])),
        filter.obj(data => data[network + '_requests'] == 1),
        gb.groupBy(['placement_id', 'uid'], true, {
            requests_in_session: gb.sum(network + '_requests'),
            bids_in_session: gb.sum(network + '_bids')
        }),
        through(function (data) {
            data.requests_in_session = data.requests_in_session - 1;
            data.bids_in_session = data.bids_in_session - data[network + '_bids']
            /*if (data.requests_in_session > 50) {
                data.requests_in_session=50;
                data.bids_in_session=25;
            }*/
            this.queue(data)
        }),
        sort(comp(placementId.concat(['requests_in_session', 'bids_in_session']))),
        gb.groupBy(placementId.concat(['requests_in_session', 'bids_in_session']), false, {
            impressions: gb.count(),
            bids: gb.sum(network + '_bids'),
            wins: gb.sum(network + '_wins'),
            revenue: gb.sum(network + '_revenue')
        }),
        gb.groupByHyb(['requests_in_session'],false, { impressions_at_request_level: gb.sum('impressions')}),
        through(function(data){
            data.bid_rate = data.bids/data.impressions;
             this.queue(data);
        }))
        
}

//'./data/cookie_sample_13_sovrn.csv', './data/cookie_sample12_k_sovrn.csv'
function runKTransform(inputFile, outputFile, network, networkLetter, options) {
    var k =
        fs.createReadStream(inputFile, 'utf8')
            .pipe(fastCsv.parse({ headers: true }))
            .pipe(K(network,networkLetter,options))
            .pipe(fastCsv.createWriteStream({ headers: true }))
            .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('pc sample k- done.') })
}

module.exports = { K, runKTransform }
