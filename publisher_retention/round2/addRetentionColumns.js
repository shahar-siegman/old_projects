const fs = require('fs')
const fastCsv = require('fast-csv')
const streamSort = require('sort-stream')
const through = require('through')
const compare = require('comparer').objectComparison2

const churnMinWeeks = 3

function streamHead(rows) {
    var i = 0
    return through(function (data) {
        this.queue(data);
        if (++i == rows)
            this.queue(null)
    })
}
var extractWeekNum = through(function (data) {
    data.week_in_year = parseInt(data.week_name.split('/')[1]);
    this.queue(data)
}, undefined, { highWaterMark: 1000 })
var sortBySiteidYearWeek = streamSort(compare(['siteid', 'year', 'week_in_year']))
var watermarkCategory = through(function (data) { data.waterMarkCategory = data.revenue < 10 ? 'below' : (data.revenue > 20 ? 'above' : 'between'); this.queue(data) })

function churnColumns() {
    var prevSiteid, lastWMcategory, weekGap, prevData = {}
    return through(function (data) {
        if (!prevSiteid || prevSiteid != data.siteid) {
            if (prevSiteid)
                prevData.isChurn = prevData.waterMarkCategory != 'below' || prevData.inactiveCount <= churnMinWeeks && prevData.inactiveCount > 0;
            prevSiteid = data.siteid;
            lastWMcategory = 'unknown'
            data.weekGap = 1
        }
        else {
            lastWMcategory = prevData.waterMarkCategory
            data.weekGap = 53 * (data.year - prevData.year) + data.week_in_year - prevData.week_in_year;
        }
        prevData.isChurn = prevData.isChurn
            || (data.weekGap + prevData.inactiveCount >= churnMinWeeks && prevData.activeCount > 0) ?
            1 : 0;

        switch (lastWMcategory) {
            case 'unknown':
                data.inactiveCount = 0;
                data.activeCount = data.waterMarkCategory == 'below' ? 0 : 1;
                break;
            case 'below':
                data.inactiveCount = (prevData.inactiveCount && data.waterMarkCategory == 'below' ? prevData.inactiveCount + 1 : 0);
                data.activeCount = data.waterMarkCategory == 'below' ?
                    (prevData.activeCount && !prevData.isChurn ? prevData.activeCount + 1 : 0) :
                    (prevData.activeCount && !prevData.isChurn ? prevData.activeCount + 1 : 1)
                break;
            case 'between':
            case 'above':
                data.inactiveCount = data.waterMarkCategory == 'below' ? 1 : 0;
                data.activeCount = (prevData.isChurn ? 0 : prevData.activeCount) + 1;
                break;
        }

        if (prevData.siteid)
            this.queue(prevData)

        prevData = data;
    }, function () {
        if (prevData) {
            prevData.isChurn = prevData.inactiveCount <= churnMinWeeks && prevData.activeCount > 0;
            this.queue(prevData);
        }
        this.queue(null);

    }, { highWaterMark: 1000 })
}

function counter(name) { var i = 0; return through(function (data) { if (i++ % 1000 == 0) console.log(name + ': ' + i); this.queue(data) }, undefined, { highWaterMark: 1000 }) }

fs.createReadStream('./retention_data_raw.csv', 'utf8')
    .pipe(fastCsv({ headers: true, highWaterMark: 1000 }))
    .pipe(extractWeekNum)
    .pipe(sortBySiteidYearWeek)
    .pipe(watermarkCategory)
    .pipe(counter('before cc'))
    .pipe(churnColumns())
    .pipe(counter('after cc'))
    .pipe(fastCsv.createWriteStream({ headers: true, highWaterMark: 1000 }))
    .pipe(fs.createWriteStream('./retention_data_with_columns.csv'))
    .on('finish', function () { console.log('retention transform done') })
