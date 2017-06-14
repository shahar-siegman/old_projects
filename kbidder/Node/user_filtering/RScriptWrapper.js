"use strict"
const fs = require('fs')
const cp = require('child_process')

const pathToRScript = 'bidrate_sequential_prediction/extract_linear_coefficients.R'
const rScriptArgument = './data/cookie_sample15K_sovrn.csv'
const rScriptOutputFile = './data/cookie_sample15K_sovrn_coeffs.csv'

module.exports = runRScript
/**
 * calls an rScript that gets a string or a few string inputs (typically an input and an output file name)
 * since the call is synchronous, when the function returns the results can be utilized.
 * @param {string} rScriptName 
 * @param {string[]|string} rScriptArguments 
 * @param {string} rScriptOutputFile 
 * @returns {boolean} success status - whether the outputFile was modified and is nonempty
 */
function runRScript(rScriptName, rScriptArguments, rScriptOutputFile) {
    rScriptArguments = validateStringOrStringArray(rScriptArguments)
    if (!rScriptArguments)
        throw new error('rScriptArguments parameter should be a string or string array')
    var blankRscriptCall = cp.spawnSync('rscript', ['']);
    if (!blankRscriptCall.status) // status of 1 is OK, null is an error
        throw new error('rscript.exe not installed or not properly configured')

    // run the script, taking the stats of the known output file before and after
    var outFileStatsBefore = fs.existsSync(rScriptOutputFile) && fs.statSync(rScriptOutputFile),
        scriptResult = cp.spawnSync('rscript', rScriptName.concat(rScriptArgument));

    var outFileStats = fs.existsSync(rScriptOutputFile) && fs.statSync(rScriptOutputFile),
        success = outFileStats && // output file exists
            (!outFileStatsBefore || outFileStats.mtime.getTime() > outFileStatsBefore.mtime.getTime()) && // didn't exist before or has a newer timestamp
            outFileStats.size > 0 // size (in bytes) > 0 
    return sucess
}


function validateStringOrStringArray(x) {
    return typeof x == 'string' ? [x] :
        Array.isArray(x) && x.every(m => typeof m == 'string') ? x :
            null;
}