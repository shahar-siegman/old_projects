const fs = require('fs')
const fastCsv = require('fast-csv')
const streamSort = require('sort-stream')
const through = require('through')
const compare = require('c:\\shahar\\node\\nodejs-common\\comparer').objectComparison2
const combiner = require('stream-combiner')
const churnMinWeeks = 3
const lowWMLevel = 14
const highWMLevel = 70

/** 
 * throws a null into the stream after _rows_ rows, which terminates further streaming.
 * @param {int} rows - number of rows (from beginning of stream) to allow through before throwing in the null
 */
function streamHead(rows) {
    var i = 0
    return through(function (data) {
        this.queue(data);
        if (++i == rows)
            this.queue(null)
    })
}

/**
 * a through-stream that adds the field 'week_in_year' to the streamed data object.
 * expects a string field called 'week_name' in the input (the read side) and parses it on the '/' character
 * TODO: check if the highWaterMark option is actually passed to the stream constructor
 */
var extractWeekNum = through(function (data) {
    data.week_in_year = parseInt(data.week_name.split('/')[1]);
    this.queue(data)
}, undefined, { highWaterMark: 1000 })

/**
 * a through stream for sorting the input records
 * note the entire file is buffered into memory in order to sort it
 */
var sortBySiteidYearWeek = streamSort(compare(['siteid', 'year', 'week_in_year']))

/**
 * a through-stream adding 'watermarkCategory' field to the data object. 
 * One of ['below','between','above'] referring to the revenue column with the thresholds of lowMLevel and highWMLevel
 */
var watermarkCategory = through(function (data) {
    data.waterMarkCategory = data.revenue < lowWMLevel ?
        'below' :
        (data.revenue > highWMLevel ? 'above' : 'between');
    this.queue(data)
})


/**
 * returns a through stream that adds the fields ['weekGap','inactiveCount','activeCount','isChurn']
 * to the data object. The following logic is applied:
 * weekGap: the number of weeks since the last entry (of the same account). The normal gap is 1
 * inactiveCount: number of consecutive weeks since the account plunged below lowWMLevel and has not regained the highWMLevel
 * activeCount: number of consecutive weeks since the account went over highWMLevel and did not churn
 * isChurn: binary (0 or 1). 1 if the account is active and had churnMinWeeks weeks of being inactive.
 */
function churnColumns() {
    var prevSiteid, lastWMcategory, weekGap, prevData = {}
    return through(function (data) {
        if (!prevSiteid || prevSiteid != data.siteid) {
            if (prevSiteid)
                prevData.isChurn = prevData.activeCount > 0 && (prevData.waterMarkCategory != 'below' || prevData.inactiveCount <= churnMinWeeks && prevData.inactiveCount > 0);
            prevSiteid = data.siteid;
            lastWMcategory = 'unknown'
            data.weekGap = 1
        }
        else {
            lastWMcategory = prevData.waterMarkCategory
            data.weekGap = 53 * (data.year - prevData.year) + data.week_in_year - prevData.week_in_year;
        }
        prevData.isChurn = prevData.isChurn
            || (data.weekGap + prevData.inactiveCount > churnMinWeeks && prevData.activeCount > 0) ?
            1 : 0;

        switch (lastWMcategory) {
            case 'unknown':
                data.inactiveCount = 0;
                data.activeCount = data.waterMarkCategory == 'above' ? 1 : 0;
                break;
            case 'below':
                data.inactiveCount = data.waterMarkCategory != 'above' ? prevData.inactiveCount + 1 : 0;
                data.activeCount = prevData.activeCount && !prevData.isChurn ? prevData.activeCount + 1 :
                    data.waterMarkCategory == 'above' ? 1 : 0;
                break;
            case 'between':
                data.inactiveCount = data.waterMarkCategory == 'below' || data.waterMarkCategory == 'between' && prevData.inactiveCount ? prevData.inactiveCount + 1 : 0;
                data.activeCount = prevData.activeCount && !prevData.isChurn ? prevData.activeCount + 1 :
                    data.waterMarkCategory == 'above' ? 1 : 0;
                break;
            case 'above':
                data.inactiveCount = data.waterMarkCategory == 'below' ? 1 : 0;
                data.activeCount = (prevData.isChurn ? 0 : prevData.activeCount) + 1; // it's still considered active even if current is below
                break;
        }

        if (prevData.siteid)
            this.queue(prevData)

        prevData = data;
    },
        /**
         * the "on end" function of the transform stream
         * used to queue the final record
         */
        function () {
            if (prevData) {
                prevData.isChurn = prevData.inactiveCount <= churnMinWeeks && prevData.activeCount > 0;
                this.queue(prevData);
            }
            this.queue(null);

        }, { highWaterMark: 1000 })
}

/**
* logs every 1000 rows 
* @param {string} name the prefix for the log row. 
*/
function counter(name) { var i = 0; return through(function (data) { if (i++ % 1000 == 0) console.log(name + ': ' + i); this.queue(data) }, undefined, { highWaterMark: 1000 }) }


function main(inputFile, outputFile, callback) {
    var theStream = combiner([
        fs.createReadStream(inputFile, 'utf8'), //'./retention_data_raw.csv'
        fastCsv({ headers: true, highWaterMark: 1000 }),
        extractWeekNum,
        sortBySiteidYearWeek,
        watermarkCategory,
        counter('before cc'),
        churnColumns(),
        counter('after cc'),
        fastCsv.createWriteStream({ headers: true, highWaterMark: 1000 }),
        fs.createWriteStream(outputFile) //'./retention_data_with_columns1.csv'
    ])
    theStream.on('finish', function () {
        console.log('retention transform done')
        if (typeof callback === 'function')
            callback(null)
    })
    return theStream
}

module.exports=main

