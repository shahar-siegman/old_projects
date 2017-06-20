"use strict"
const fs = require('fs')
const parseCsv = require('parse-csv')

var str =  fs.readFileSync('./data/grouped_by_res_wb_sample1N_coeffs.csv','utf8')
if (!str)
    throw new error("couldn't read file")

console.log('str preview:' + str.slice(0,22))
//fs.readFileSync('./data/grouped_by_res_wb_sample1N_coeffs.csv','utf8')
var records = JSON.parse(parseCsv('json', str, { headers: { included: true } }))

console.log(typeof records)
console.log(`parsed  ${records.length} rows\n ${Object.keys(records[0]).length} columns. first row:\n${JSON.stringify(records[0])}`)