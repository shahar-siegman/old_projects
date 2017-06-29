"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('fast-stream-sort')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const runRScript = require('./RScriptWrapper')

const inputFile = './data/grouped_by_res_wb_sample3.csv',
    dataFile = './data/grouped_by_res_wb_sample3N.csv',
    rScriptFile = './bidrate_sequential_prediction/extract_linear_coefficients2.R',
    rOutputFile = './data/grouped_by_res_wb_sample3N_coeffs.csv'


fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(filter.obj(x => x.res < 50))
    .pipe(through(function (data) {
        var res = {
            //name: data.name,
            tag_url: data.tag_url,
            placement_id: data.placement_id,
            network: data.network,
            has_cookie: data.has_cookie,
            res: data.res,
            //            res_cookies: data.has_cookie? data.res: 0,
            wb: data.wb == data.res ? null : data.wb,
            wb_res_interaction: data.wb == data.res ? null : data.res * data.wb,
            bid_rate_so_far: data.wb == data.res ? null : data.wb / data.res,
            ones: 1,
            bid_rate_eq: data.wb == data.res && data.with_response ? data.with_bid / data.with_response : null,
            bid_rate_not_eq: data.res != data.wb && data.with_response ? data.with_bid / data.with_response : null,
            bid_value_eq: data.wb != data.res ? null : data.total_bid_value / data.with_bid,
            bid_value_not_eq: data.wb == data.res ? null : data.total_bid_value / data.with_bid,
        }
        this.queue(res);
    }))
/*    .pipe(sort(comp(['placement_id', 'network'])))
    .pipe(gb.groupByHyb(['placement_id', 'network'], false, { n_points: gb.count() }))
    .pipe(filter.obj(x => x.n_points > 3))
 */   .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(dataFile, 'utf8')).on('finish', function () {
        console.log('running R script')
        var success = runRScript(rScriptFile,
            [dataFile, 'tag_url,placement_id,network,has_cookie', 'bid_rate_eq,bid_rate_not_eq,bid_value_eq,bid_value_not_eq'],
            rOutputFile)
            
        console.log('R script complete with status ' + success)
    })
