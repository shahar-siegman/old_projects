const k = require('./K-bidding_sequence_markov')
const monteCarloSimulation = require('./runMonteCarloSimulation')


function runKTransform() {
    k.runKTransform('./data/cookie_sample13_sovrn.csv', './data/cookie_sample13K_sovrn.csv', 'sovrn', 'S', { aggregate_placementId: false })
}

function runMonteCarloSimulation() {
    monteCarloSimulation(function(simResult, stats) {
        console.log('stats: '+ JSON.stringify(stats))
    })
}

//runMonteCarloSimulation();