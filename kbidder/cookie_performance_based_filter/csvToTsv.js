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

fs.createReadStream('./data/pc_sample_3.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(fastCsv.createWriteStream({headers: true, delimiter: '\t', quote:'\0',escape:null}))
    .pipe(fs.createWriteStream('./data/pc_sample_3.tsv'))
    .on('finish', function() {console.log('csv transform done')})