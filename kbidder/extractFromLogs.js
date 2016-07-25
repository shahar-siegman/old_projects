const fs = require('fs');
var readline = require('readline');
var csvWriter = require('csv-write-stream');
var writer = csvWriter();
var inputFiles = ['kbidder_10_11.txt', 'kbidder_11_12.txt', 'kbidder_12_13.txt', 'kbidder_13_14.txt', 'kbidder_14_15.txt', 'kbidder_15_16.txt'];
var inputFile='';
//
function loadData(dataFile) {
    var outFile = inputFile.split('.')[0]+'_parsed.csv';
    writer.pipe(fs.createWriteStream(outFile));
    var lineReader = readline.createInterface({
        input: fs.createReadStream(dataFile)});
    
    lineReader
    .on("line", function(row){
        //data.moment = moment(data.date, "YYYY-MM-DD");
        handleLine(row);
    })
    .on("end", function(){
        console.log("done");
        writer.end();
    });

}

function handleLine(row) {
    row =row.toString();
    var rowParts = row.split('-->');
    var timeAndTypeParts = rowParts[0].split(':');
    //console.log(rowParts[1].trim());
    var record = JSON.parse(rowParts[1].trim());
    var basicProperties = {
        time: (timeAndTypeParts[1]+':'+timeAndTypeParts[2]+':'+timeAndTypeParts[3]).trim(),
        log_type: timeAndTypeParts[0].trim(),
        tagid: record.tagid,
        cb: record.cb,
        ver: record.v,
        browser: record.browser
    }
    writer.write(basicProperties);
    return;
    // if (basicProperties.log_type != "placement" || (record.parent && record.parent.length >0) )        return; // skip row if it was mistakenly matched
    var extendedProperties;
    if (basicProperties.log_type=="placement" && record.hdbdId) // there is hdbd data
    { 
        var hb=JSON.parse(record.hb);
        var bidders = {};
        for (var i=0; i< hb.length; i++ ) {
            if(hb[i].code)
                bidders[hb[i].code]=hb[i].cpm;
        }
        extendedProperties = {
            l1_bid: bidders && bidders.l1 ? bidders.l1 : null,
            o2_bid: bidders && bidders.o2 ? bidders.o2 : null,
            p5_bid: bidders && bidders.p5 ? bidders.p5 : null,
            kbwt: record.kbwt,
            served_tag: record.o.split('|').pop(),
            cpm: record.cpm,
            wb: record.wb,
            sent_bid: record.sb
        }
    }
    else 
    {
        extendedProperties = {
            l1_bid: null,
            o2_bid: null,
            p5_bid: null,
            kbwt: null,
            served_tag: record.o? record.o.split('|').pop() : null ,
            cpm: record.cpm,
            wb: null,
            sent_bid: null
        }
    }

    for (attr in extendedProperties) basicProperties[attr]=extendedProperties[attr];


    //console.log('next!');
}
/*
for (var i=1; i< inputFiles.length; i++) {
    inputFile= inputFiles[i];
    console.log('processing ' + inputFile);
    loadData(inputFile);
    console.log('done with ' + inputFile);
} */
//inputFile='kbidder_10_11.txt';
//inputFile='kbidder_11_12.txt';
//inputFile='kbidder_12_13.txt';
//inputFile='kbidder_13_14.txt';
//inputFile='kbidder_14_15.txt';
//inputFile='kbidder_15_16.txt';
inputFile='result.txt'
loadData(inputFile);

