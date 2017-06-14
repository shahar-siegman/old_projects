"use strict"
const through = require('through')
const combiner = require('stream-combiner')
const gb = require('stream-group-by')
const sort = require('sort-stream')
const comp = require('comparer').objectComparison2
const fastCsv = require('fast-csv')
const fs = require('fs')
const filter = require('stream-filter')
const commission = { Y: 1 - 0.36, p: 1 - 0.08, l: 1 - 0, S: 1 - 0, e: 1-0 }

var rowCount = 0

var errorStream = fs.createWriteStream('defy_runner_ups_errors.log', 'utf8')
var a = fs.createReadStream('defy_runner_ups1.csv', 'utf8')
    .pipe(fastCsv.parse({ headers: true }))
    .pipe(through(function (data) {
        rowCount++;
        if (data.pbsbids.length && data.hdbd_json.length) 
            try {
            var sentBids = JSON.parse(data.pbsbids),
                receivedBids = JSON.parse(data.hdbd_json)
            }
        catch (err) {
            errorStream.write(rowCount + ": failed to parse \n'" + data.pbsbids + "'\n '" + data.hdbd_json + "'\n")
            return
        }
        else return
        var winnerSentRecord,
            result = {}
        while (sentBids.length && !winnerSentRecord) {
            var bid = sentBids.pop();
            if (bid.bid_src == 'defy')
                winnerSentRecord = bid;
        }
        if (!winnerSentRecord) {
            errorStream.write(rowCount + ': cannot find defy in ' + data.pbsbids)
            return
        }
        var winnerReceivedRecordKey = winnerSentRecord.code + (winnerSentRecord.rb ? "_rb" : ""),
            winnerReceivedRecord = receivedBids[winnerReceivedRecordKey]
        if (!winnerReceivedRecord) {
            errorStream.write(rowCount + ": could not match sent and received records\n" + data.pbsbids + "\n" + data.hbdb_json)
            return
        }
        //delete receivedBids[winnerReceivedRecordKey]
        Object.keys(receivedBids).forEach(function (network) {
            if (network[0] != 'Y') {
                var timeDiff = receivedBids[network].rests - winnerReceivedRecord.rests,
                    bidRatio = receivedBids[network].cpm * commission[network[0]] / (winnerReceivedRecord.cpm * commission['Y']),
                    timeDiffCat = timeDiff < 0 ? "-1" :
                        timeDiff < 100 ? "0-100" :
                            timeDiff < 500 ? "100-500" : "501";
                if (bidRatio > 0 && (!result[timeDiffCat] || bidRatio > result[timeDiffCat].ratio)) {
                    bidRatio = Math.round(bidRatio*1000)/1000;
                    result[timeDiffCat] = result[timeDiffCat] || {};
                    result[timeDiffCat].ratio = bidRatio
                    result[timeDiffCat].network = network
                }
            }
        })
        data.result = JSON.stringify(result)
        this.queue(data);
    }

    ))


a.pipe(fastCsv.createWriteStream({ headers: true }))
    .pipe(fs.createWriteStream('defy_runner_ups1_a.csv', 'utf8')).on('finish', function () { console.log('cookie sample g - done') })


