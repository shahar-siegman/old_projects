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

const inputFile = './data/pc_longtail_sample1.csv'
//const queryFile = '/queries/rs_query_first_impression_performance_by_pc_category.sql'
var outputFile = function(inputFile) { 
    var parts = path.parse(inputFile);
    return path.format({dir: parts.dir, name: parts.name + '_L', ext: parts.ext })
}(inputFile)

fs.createReadStream(inputFile, 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        data.pc_res_bin = data.l_pc_res == 0 ? 0 :
            data.l_pc_res < 26 ? 20 :
                26;
        data.l_pc_wb = Math.min(data.l_pc_wb,1)
        this.queue(data);
    }))
    .pipe(sort(comp(['placement_id', 'pc_res_bin', 'l_pc_wb', 'filtered0', 'has_cookie'])))
    .pipe(gb.groupBy(['placement_id', 'name','tag_url','network','pc_res_bin', 'l_pc_wb', 'filtered0', 'has_cookie'],
        false,
        {
            imps: gb.sum('impressions'),
            revenue: gb.sum('this_network_cpm'),
            others_revenue: gb.sum('other_networks_cpm')
        }))
    .pipe(filter.obj( x => x.imps > 250))
    .pipe(through(function(data) {
        data.rcpm = data.revenue / data.imps;
        data.others_rcpm = data.others_revenue / data.imps;
        this.queue(data);
    }))
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream(outputFile, 'utf8')).on('finish', function () { console.log('pc sample l- done.') })

