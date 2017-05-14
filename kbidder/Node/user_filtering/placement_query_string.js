const format = require('string-format')
const quote = require('quote')({ quotes: "'" })
const fs = require('fs')

module.exports = queryString
const queryTemplate = fs.readFileSync('./queries/single_placement_sample.sql', 'utf8')
function queryString(options) {
    if (!options)
        throw new error('options parameter missing')

    const necessaryKeys = ['placementId', 'date', 'sampleRatio']

    necessaryKeys.forEach(function (key) {
        if (!options[key])
            throw new error(key + ' field missing in input')
    })

    var cookieSuffixCount =Math.ceil(options.sampleRatio * 256),
    queryScope = {
        placement_id: quote(options.placementId),
        start_time: quote(options.date + ' 00:00'),
        end_time: quote(options.date + ' 23:59:59'),
        cookie_suffix: random2DigitHex(cookieSuffixCount).map(quote).join(',')
    },
        query = format(queryTemplate, queryScope)

    return query

}


function random2DigitHex(n) {
    const chars = '0123456789abcdef';
    
    var hexes = Array.apply(null,Array(256)).map(function (v, i) {
        //console.log( 'i: '+ Math.floor(i / 16) + ', '+ i % 16)
        return chars[Math.floor(i / 16)] + chars[i % 16]
    });
    shuffleInPlace(hexes)
    return hexes.slice(0, n)
}

function shuffleInPlace(array) {
    var currentIndex = array.length, temporaryValue, randomIndex;

    // While there remain elements to shuffle...
    while (0 !== currentIndex) {

        // Pick a remaining element...
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;

        // And swap it with the current element.
        temporaryValue = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = temporaryValue;
    }

}