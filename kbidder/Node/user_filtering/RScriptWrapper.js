"use strict"
const fs = require('fs')
const cp = require('child_process')

/*
const pathToRScript = 'bidrate_sequential_prediction/extract_linear_coefficients.R'
const rScriptArgument = './data/cookie_sample15K_sovrn.csv'
const rScriptOutputFile = './data/cookie_sample15K_sovrn_coeffs.csv'
*/

module.exports = runRScript
/**
 * calls an rScript that gets a string or a few string inputs (typically an input and an output file name)
 * since the call is synchronous, when the function returns the results can be utilized.
 * @param {string} rScriptName  - the R file to run 
 * @param {string[]|string} rScriptArguments - command line arguments, parsed n R using commandArgs()
 * @param {string} rScriptOutputFile - optional. used in the Node code to check if this file was changed.
 * @returns {boolean} success status - whether the outputFile was modified and is nonempty
 */
function runRScript(rScriptName, rScriptArguments, rScriptOutputFile) {
    rScriptOutputFile = rScriptOutputFile || null;
    rScriptArguments = validateStringOrStringArray(rScriptArguments)
    if (!rScriptArguments)
        throw new error('rScriptArguments parameter should be a string or string array')
    var blankRscriptCall = cp.spawnSync('rscript', ['']);
    if (!blankRscriptCall.status) // status of 1 is OK, null is an error
        throw new error('rscript.exe not installed or not properly configured')

    console.log('call: rscript ' + [rScriptName].concat(rScriptArguments).join(' '))
    // run the script, taking the stats of the known output file before and after
    var outFileStatsBefore = rScriptOutputFile && fs.existsSync(rScriptOutputFile) && fs.statSync(rScriptOutputFile),
        scriptResult = cp.spawnSync('rscript', [rScriptName].concat(rScriptArguments));


    console.log(scriptResult.stdout.toString())
    if (scriptResult.stderr)
        console.error(scriptResult.stderr.toString())
    console.log('*** end R output ***')
    var outFileStats = rScriptOutputFile && fs.existsSync(rScriptOutputFile) && fs.statSync(rScriptOutputFile),
        success = outFileStats && // output file exists
            (!outFileStatsBefore || outFileStats.mtime.getTime() > outFileStatsBefore.mtime.getTime()) && // didn't exist before or has a newer timestamp
            outFileStats.size > 0 // size (in bytes) > 0 
    return success
}


function validateStringOrStringArray(x) {
    return typeof x == 'string' ? [x] :
        Array.isArray(x) && x.every(m => typeof m == 'string') ? x :
            null;
}