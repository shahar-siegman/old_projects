"use strict";
/* 
retention metric design:
account phases are defined as follows:
- infant 1-4 weeks
- juvenile 5-13 weeks
- adult 14+ weeks
- revived: active after they were counted as churn
for each week, phase
- the number of active accounts
- the number of churned accounts
- the number of new accounts
- the total revenue in the last 13 weeks for active accounts
- the total revenue in the last 13 weeks for churn accounts
*/

const through = require('through')
const sortStream = require('sort-stream')
const gb = require('c:\\shahar\\node\\nodejs-common\\stream-group-by')
const comp = require('c:\\shahar\\node\\nodejs-common\\comparer').objectComparison2
const combine = require('stream-combiner')

function addPhase() {
    const ageColumn = 'activeCount',
        phaseColumn = 'accountPhase',
        cycleColumn = 'activeCycle',
        groupMaxs = [0, 4, 13, Infinity],
        groupTags = ['O-inactive', 'A-infant', 'B-juvenile', 'C-adult'],
        revivedPhaseTag = 'revived'
    return through(function (data) {
        var phase, groupInd;
        if (data[cycleColumn] > 1)
            phase = revivedPhaseTag;
        else {
            groupInd = groupMaxs.findIndex(function (el) {
                return el >= +data[ageColumn];
            })
            phase = groupTags[groupInd];
        }
        data[phaseColumn] = phase;
        this.queue(data);
    })
}

function addChurnedRevenue() {
    return through(function (data) {
        data.churnedRevenue = data.avgRevenue * +data.isChurn;
        this.queue(data)
    })
}

function main() {
    var addActiveCycleAndAverageRevenueColumns = gb.groupBy(['siteid'], true, {
        activeCycle: gb.countMatches((data) => data.activeCount == 1),
        avgRevenue: gb.movingAverage('revenue', 'weekGap', 13)
    }),
        addPhaseColumn = addPhase(),
        addChurnedRevenueColumn = addChurnedRevenue(),
        sortOnWeekAndPhase = sortStream(comp(['week_name', 'accountPhase'])),
        summarize = gb.groupBy(['week_name', 'accountPhase'], false,
            {
                activeAccounts: gb.countMatches((data) => data.activeCount >= 1),
                churnedAccounts: gb.sum('isChurn'),
                newAccounts: gb.countMatches((data) => data.activeCount == 1 && data.activeCycle == 1),
                revivedAccounts: gb.countMatches((data) => data.activeCount == 1 && data.activeCycle > 1),
                totalChurnedRevene: gb.sum('churnedRevenue')
            })
            
    return combine(addActiveCycleAndAverageRevenueColumns,
        addPhaseColumn,
        addChurnedRevenueColumn,
        sortOnWeekAndPhase,
        summarize)
}

module.exports = main;

