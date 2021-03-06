"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('./mySortTransform')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const shallowCopy = require('shallow-copy')

const networkLetters = ['S', 'p', 'l', 'e']
const networks = ['sovrn', 'pubmatic', 'cpx', 'openx']
const maxFreq = 5;

var counter1 = 0;
// analysis of predictive value of performance counters:
// group by placement_id, network, impression number in session based on the count in pc.any.res, and (binned) bid ratio from per-network performance counters 
// calculate the win-rate and cpm for each such group and try to find functional relation
var a = fs.createReadStream('./data/pc_sample_4.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        var self = this,
            freq;
        try {
            var pc = JSON.parse(data.pc)
        }
        catch (err) {
            pc = null;
            freq = -1;
        }
        if (pc) {
            freq = pc.any && pc.any.res >= 0 ? pc.any.res : 0;
        }
        networks.forEach(function (network, i) {
            if (pc && pc[network] && pc[network].res >= 0 && pc[network].wb >= 0) {
                var bidRatio = +pc[network].wb / +pc[network].res,
                    bidRatioRound = Math.round(bidRatio * 10) / 10;
            }
            else {
                bidRatio = null;
                bidRatioRound = null;
            }
            var q = shallowCopy(data);
            q = Object.assign(q, {
                network: network,
                frequency: Math.min(freq, 5),
                bidRatioRound: bidRatioRound,
                isWin: +(data.kb_code[0] == networkLetters[i]),
                isServedWin: +(data.isWin > 0 && data.cpm > 0)
            });
            q.cpm = q.isWin ? data.cpm : 0;
            self.queue(q);
        });
    }, function () { console.log('checkpoint 1 passed'); this.queue(null) }));

var f = a
    .pipe(sort(comp(['placement_id', 'network', 'bidRatioRound', 'frequency'])))
    .pipe(gb.groupBy(['placement_id', 'network', 'bidRatioRound', 'frequency'], false, {
        impressions: gb.count(),
        wins: gb.sum('isWin'),
        winValue: gb.sum('cpm')
    }))
    .pipe(through(function (data) {
        data.winRate = data.wins / data.impressions;
        data.rcpm = data.winValue / data.impressions;
        this.queue(data);
    }, function () {
        var now = (new Date()).toISOString();
        console.log(now + ': f - checkpoint passed')
        this.queue(null);
    }));


f.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('./data/pc_sample4_f.csv', 'utf8')).on('finish', function () { console.log('pc sample f - done') })


var globalNow = (new Date).toISOString();
console.log('starting at ' + globalNow);

