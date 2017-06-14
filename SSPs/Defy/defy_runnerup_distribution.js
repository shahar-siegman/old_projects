"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const arrayMax = (x) => Math.max.apply(undefined,x)
var a = fs.createReadStream('defy_runner_ups1_a.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))

var b = a
    .pipe(through(function(data){
        delete data.pbsbids
        delete data.hdbd_json
        var result = JSON.parse(data.result)
        var roundedRatios = ['-1','0-100','100-500'].map(x => result[x]&& result[x].ratio).reduce(function(output,ratio) {
            if (ratio) {
                output = Math.max(output,Math.round(ratio*10)/10);
            }
            return output;
        },null)
        data.ratio = roundedRatios;
        this.queue(data);
    }))
    .pipe(sort(comp(['ratio'])))
    .pipe(gb.groupBy(['ratio'],false,{impressions: gb.count(), komoonaValue: gb.sum('kb_sold_cpm') }))
    .pipe(gb.groupByHyb([],false,{totalValue: gb.sum('impressions')}))
    .pipe(through(function(data) {
        data.komoonaValuePortion = Math.round(1000*data.komoonaValue / data.totalValue)/10 + '%';
        data.komoonaValue = Math.round(data.komoonaValue*10)/10;
        this.queue(data)
    }))

b.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('defy_runner_ups1_b.csv', 'utf8')).on('finish', function () { console.log('defy runner ups b - done') })




