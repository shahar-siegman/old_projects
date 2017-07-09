"use strict"

module.exports = { constructUniversalTransitionMap, pathImpsAndValueSingleState }

function constructUniversalTransitionMap(playProb, successProb, bidValue, horizonRes) {
    return function (res, wb) {
        var currSuccessProb = successProb(res, wb),
            transition0Prob = playProb[res] * (1 - currSuccessProb),
            transition1Prob = playProb[res] * currSuccessProb,
            transitionImps = res == horizonRes - 1 ? playProb[horizonRes] : 1,
            transition1Value = bidValue(res, wb) * transitionImps;
        return { transition0Prob, transition1Prob, transitionImps, transition1Value }
    }
}

function pathImpsAndValueSingleState(pathStartState, universalTransitionMap, maxRes, returnProbMap) {
    var probMap = {},
        valueMap = {},
        cumulativeImps = 0,
        cumulativeValue = 0,
        maxFeasibleWb = res => res - pathStartState.res + pathStartState.wb;
    probMap[pathStartState.res] = {}
    probMap[pathStartState.res][pathStartState.wb] = 1;
    for (var res = pathStartState.res; res <= maxRes; res++) {
        probMap[res + 1] = {}
        for (var wb = pathStartState.wb; wb <= maxFeasibleWb(res); wb++) {
            var t = universalTransitionMap(res, wb);
            probMap[res + 1][wb] = (probMap[res + 1][wb] || 0) + t.transition0Prob * probMap[res][wb]
            probMap[res + 1][wb + 1] = (probMap[res + 1][wb + 1] || 0) + t.transition1Prob * probMap[res][wb]
            cumulativeImps += probMap[res][wb] * (t.transition1Prob + t.transition0Prob) * t.transitionImps;
            cumulativeValue += probMap[res][wb] * t.transition1Prob * t.transition1Value;
        }
    }
    if (returnProbMap) {
        for (res = maxRes; res >= pathStartState.res; res--) {
            valueMap[res] = {}
            for (var wb = pathStartState.wb; wb <= maxFeasibleWb(res); wb++) {
                t = universalTransitionMap(res, wb);
                var nextStepsExpectedValue = valueMap[res + 1] && t.transition1Prob * valueMap[res + 1][wb + 1] + t.transition0Prob * valueMap[res + 1][wb] || 0;
                valueMap[res][wb] = nextStepsExpectedValue + t.transition1Prob * t.transition1Value;
            }
        }
        var ret = { impressions: cumulativeImps, value: cumulativeValue, probMap: probMap, valueMap: valueMap };
    }
    else
        var ret = { impressions: cumulativeImps, value: cumulativeValue };
    return ret;
}


