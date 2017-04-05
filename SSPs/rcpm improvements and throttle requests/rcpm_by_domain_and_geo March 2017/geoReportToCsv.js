const fs = require('fs')
const fastCsv = require('fast-csv')
const streamify = require('stream-array')

var a = fs.readFileSync('./geos/pubmatic-weekly-geo-report.json', 'utf8')
a= JSON.parse(a);
console.log('length: '+a.rows.length)
var b = a.rows.map(function (row) {
    return {
        countryId: a.displayValue.countryId[row[0]],
        revenue: row[1],
        totalImpressions: row[2],
        paidImpressions: row[3],
        ecpm: row[4]
    }
})

streamify(b).pipe(fastCsv.createWriteStream({headers:true})).pipe(fs.createWriteStream('./geos/geo_report.csv','utf8')).on('finish',function() {console.log('done')})