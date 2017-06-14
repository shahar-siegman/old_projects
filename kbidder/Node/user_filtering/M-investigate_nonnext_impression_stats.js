"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const path = require('path')
const filter = require('stream-filter')

const inputFile = './data/pc_res5_wb0_sample5.csv'
var outputFile = function (inputFile) {
    var parts = path.parse(inputFile);
    return path.format({ dir: parts.dir, name: parts.name + '_M', ext: parts.ext })
}(inputFile)

const inputContainsWbAt5ResColumn = true;
var additionalGroupColum = inputContainsWbAt5ResColumn? ['wb_at_5_res'] : []

 
console.log((new Date).toISOString().slice(0, 19) + ': ' + inputFile + '  ---->  ' + outputFile)
var rowCount=0;
// the dataset comes sorted by placement_id, uid, timestamp

var tmp = fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        data.pc_res = +data.pc_res;
        data.pc_wb0 = data.pc_wb > 0;
        this.queue(data);
    }))
    .pipe(sort(comp(['placement_id','uid','timestamp'])))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, { pc_wb_lag: gb.lag('pc_wb',1) }))
    .pipe(through(function (data) {
        data.bid = data.pc_wb > data.pc_wb_lag ? 1 : 0
        data.first_user_bid = data.bid && (+data.pc_wb_lag === 0) ? 1 : 0
        this.queue(data)
    }))

tmp 
    .pipe(sort(comp(['placement_id', 'pc_res'].concat(additionalGroupColum).concat(['uid']))))
    .pipe(gb.groupBy(['placement_id', 'name', 'tag_url', 'network', 'pc_res'].concat(additionalGroupColum),
        false,
        {
            imps: gb.count(),
            revenue: gb.sum('this_network_cpm'),
            have_bids: gb.sum('pc_wb0'),
            bids: gb.sum('bid'),
            first_bids: gb.sum('first_user_bid')
        }))
    .pipe(through(function (data) {
        data.rcpm = data.revenue / data.imps;
        data.bid_rate = data.bids / data.imps;
        data.first_bid_rate = data.first_bids / data.imps;
        this.queue(data);
    }))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () {
        console.log((new Date).toISOString().slice(0, 19) + ': pc sample m- done.')
    })

/*    .pipe(through(function (data) {
        if (rowCount++ < 10000)
            this.queue(data);
    }))
*/