const queryServer = require('query-server');
const fs = require('fs');

function joinData()
{
    var emptyA = { 
        sitename:'',
        name:'',
        placement_id:'',
        date:'',
        entity_type:'',
        impressions: 0,
        fill: 0,
        revenue: 0 },
    emptyB = { 
        placement_id:'',
        date_:'',
        served_type:'',
        imps:0,
        cost:0,
        revenue:0,
        hb_tag_value:0 };

    var streamA = csv2array.CSVfileReader('mysql_revenue_by_tag_entity_type.csv', emptyA);
    var streamB = csv2array.CSVfileReader('redshift_cost_and_revenue_by_tag_entity_type.csv', emptyB);

    comp = function (a, b) { 
        a.account < b.account ? -1 : a.account == b.account ? 0 : 1; }
    var outStream = fs.createWriteStream('costAndRevenueJoined.csv');
  
}

function joinByEntityType() {
    var mysqlQuery = fs.readFileSync('queries/mysql_revenue_by_tag_entity_type.sql'),
        redshfitQuery = fs.readFileSync('queries/redshift_cost_and_revenue_by_tag_entity_type.sql')
    queryServer.runDBFlow(mysqlQuery, () => redshfitQuery, handleResults);
}

function handleResults(err, result) {
    if (err)
        throw err;
    1;
}