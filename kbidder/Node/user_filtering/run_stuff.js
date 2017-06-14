const k = require('./K-bidding_sequence_markov')
const monteCarloSimulation = require('./monteCarloSimulationRunner')


function runKTransform() {
    k.runKTransform('./data/cookie_sample15.csv', './data/cookie_sample14K_sovrn.csv', 'sovrn', 'S')
}

function runMonteCarloSimulation() {
    monteCarloSimulation(function(simResult, stats) {
        console.log('stats: '+ JSON.stringify(stats))
    })
}

//monteCarloSimulation();
runKTransform();