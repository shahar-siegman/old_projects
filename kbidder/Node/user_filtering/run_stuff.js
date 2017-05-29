const k = require('./K-bidding_sequence_markov')
const monteCarloSimulation = require('./runMonteCarloSimulation')


function runKTransform() {
    k.runKTransform('./data/cookie_sample14.csv', './data/cookie_sample14K_sovrn.csv', 'sovrn', 'S')
}

function runMonteCarloSimulation() {
    monteCarloSimulation(function(simResult, stats) {
        console.log('stats: '+ JSON.stringify(stats))
    })
}

//monteCarloSimulation();
runKTransform();