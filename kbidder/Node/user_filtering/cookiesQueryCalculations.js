const format = require('string-format')
const quote = require('quote')({ quotes: "'" })
const fs = require('fs')

module.exports = cookiesQueryCalculations
//const queryTemplate = fs.readFileSync('./queries/single_placement_sample.sql', 'utf8')
//const necessaryKeys = ['placementId', 'date', 'sampleRatio']


function cookiesQueryCalculations(queryParams) {
    cookieSuffixCount = Math.ceil(queryParams.sampleRatio * 256),
        queryScope = {
            placement_id: quote(queryParams.placementId || queryParams.placement_id),
            start_time: quote(queryParams.date + ' 00:00'),
            end_time: quote(queryParams.date + ' 23:59:59'),
            cookie_suffix: random2DigitHex(cookieSuffixCount).map(quote).join(',')
        }
    return queryScope;
}

function random2DigitHex(n) {
    const hexDigits = '0123456789abcdef';
    var hexes = Array.apply(null, Array(256)).map(function (v, i) {
        return hexDigits[Math.floor(i / 16)] + hexDigits[i % 16]
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