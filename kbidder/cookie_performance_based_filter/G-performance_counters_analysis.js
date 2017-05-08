"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const shallowCopy = require('shallow-copy')

const networkLetters = ['S', 'p', 'l', 'e']
const networks = ['sovrn', 'pubmatic', 'cpx', 'openx']
const maxFreq = 5;

var ifNan = x => isNaN(x) ? 0 : x;
var g = fs.createReadStream('./data/pc_sample3_f.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        data.bidRatioReverse = data.frequency == maxFreq ? -data.bidRatioRound : -2
        data.bidRatioRound = data.frequency == maxFreq ? data.bidRatioRound : "lo";
        data.frequency = data.frequency == maxFreq ? "2" : "1";
        this.queue(data);
    }))
    .pipe(sort(comp(['placement_id', 'network', 'frequency', 'bidRatioReverse'])))
    .pipe(gb.groupBy(['placement_id', 'network', 'frequency', 'bidRatioRound'], false, {
        impressions: gb.sum('impressions'),
        wins: gb.sum('wins'),
        winValue: gb.sum('winValue')
    }))
    .pipe(gb.groupByHyb(['placement_id', 'network'], true, {
        totalImps: gb.sum('impressions'),
        totalWinValue: gb.sum('winValue')
    }))
    .pipe(gb.groupBy(['placement_id', 'network'], true, {
        cumImps: gb.sum('impressions'),
        cumWinValue: gb.sum('winValue')
    }))
    .pipe(through(function (data) {
        data.retainedImpsPortion = ifNan(data.cumImps / data.totalImps);
        data.retainedValuePortion = ifNan(data.cumWinValue / data.totalWinValue);
        data.leverage = ifNan((1 - data.retainedImpsPortion) / (1 - data.retainedValuePortion));
        this.queue(data);
    }))


g.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./data/pc_sample3_g.csv', 'utf8')).on('finish', function () { console.log('pc sample g - done') })


