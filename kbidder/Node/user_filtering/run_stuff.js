const k = require('./K-bidding_sequence_markov')

k.runKTransform('./data/cookie_sample13_sovrn.csv', './data/cookie_sample13K_sovrn.csv','sovrn','S', {aggregate_placementId: false})