const metric = require('./retentionMetric.js')
const fastCsv = require('fast-csv')
const fs = require('fs')

fs.createReadStream('retention_data_with_columns1.csv', 'utf8')
    .pipe(fastCsv({ headers: true }))
    .pipe(metric())
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('retention_summed.csv', 'utf8')).on('finish',function() {console.log('metric test done')})