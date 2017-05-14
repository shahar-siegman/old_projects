qs = require('./placement_query_string')


console.log(qs({placementId: '9b78b40a58202cfa68a9e1fde3d0ef6c', date: (new Date()).toISOString().slice(0,10), sampleRatio: 0.1}))