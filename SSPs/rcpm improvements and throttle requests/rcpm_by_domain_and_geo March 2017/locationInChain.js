const fs = require('fs')
const fastCsv = require('fast-csv');
const through = require('through');

var a = fastCsv.parse({ headers: true })
var b = through(function (data) {
    var tags = data.chain.split(':');
    var network = data.tag_name[0];
    data.location = tags.slice(0, data.ordinal).reduce(function (s, tag, ind) { return s + (tag[0] == network ? 1 : 0) }, 0);
    this.queue(data);
})

fs.createReadStream('performance_with_history.csv')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(b)
    .pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('chain_after.csv')).on('finish', () => console.log('done'))