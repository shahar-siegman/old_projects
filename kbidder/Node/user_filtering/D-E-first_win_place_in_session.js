"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')

const networkLetters = ['S', 'p', 'l', 'e']
var networkRbLag = networkLetters.reduce(function(agg, letter) {
    agg[letter+'_rb_lag']=gb.lag(letter+'_rb_bid',1)
},{})
    
String.prototype.in = function (arr) { return arr.some(el => this == el) }

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



// half-baked attempt to account for value of rb in next bid. drop this code at your leisure.
var e = fs.createReadStream('data/cookie_sample4.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true, discardUnmappedColumns: false }))
    .pipe(sort(comp(['placement_id', 'uid', 'timestamp'])))
    .pipe(through(function (data) {
        var hdbd_json = JSON.parse(data.hdbd_json);
        Object.keys(hdbd_json).filter(x => x.match(/_rb$/)).forEach(function (key) {
            var tag = key.split('_').shift(),
                networkLetter = tag[0];
            if (networkLetter.in(networkLetters))
                data[networkLetter + '_bid'] = hdbd_json[tag] && hdbd_json[tag].cpm;
            data[networkLetter + '_rb_bid'] = hdbd_json[key] && hdbd_json[key].cpm;
            this.queue(data);
        })
    }))
    .pipe(gb.groupBy(['placement_id', 'uid'], true, networkRbLag)