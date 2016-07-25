var fs = require('fs');
var moment = require('moment');
var csvWriter = require('csv-write-stream');
var writer = csvWriter();

var client = {
  user: "master",
  db: "logs",
  password: "ntxyrNtxyr77",
  port: 5439,
  host: 'kmnspark.crc6oizgxxw8.us-east-1.redshift.amazonaws.com'
};

var outFileName = 'kbidder_updates_'+moment().format('YYYY-MM-DD-HH')+'.csv'
var a=fs.createWriteStream(outFileName);
writer.pipe(a);
var rssql = require('redshift-sql')(client);
var query1 = `select placement_id, cb, client_ip, final_state, cpm from aggregated_logs_5 where placement_id = '83d6f1934c618a6b7f30f17f1671d794' 
and timestamp between '2016-07-19 08:00:00' and '2016-07-19 09:00:00'`
var query = `
select * from (
select placement_id
  , date_trunc('hour',timestamp) "time"
  , max(timestamp) latest_entry
  , count(1) auctions
  , sum(case when final_state in ('tag', 'stat-1',  'placement', 'js-err') and length(hdbd_json)>4 then 1 else 0 end) kb_wins
  , sum(case when final_state='placement' and strpos(a.hdbd_json, a.served_tag) > 0 AND length(a.served_tag) > 1 then 1 else 0 end) hb_tag_served
  , sum(case when final_state in ('tag', 'stat-1',  'placement', 'js-err') and length(hdbd_json)<=4 then 1 else 0 end) chain_attempts_no_hdbd
  , sum(case when final_state in ('tag', 'stat-1', 'js-err') and length(hdbd_json)>4 then 1 else 0 end) discrepancy
  , sum(case when final_state='placement' and strpos(a.hdbd_json, a.served_tag) <= 0 AND length(a.served_tag) > 1 then 1 else 0 end) chain_tag_served
  , sum(case when kb_sold_cpm>0 then 1 else 0 end) obligated_cost_count
  , sum(case when kb_sold_cpm>0 then kb_sold_cpm::decimal(6,2) else 0.00 end) obligated_cost_value
  , sum(case when cpm>0 then cpm::decimal(6,2) else 0 end) hdbd_revenue
 from aggregated_logs_5 a
 where timestamp >= dateadd('day', -2, current_date) 
 and url not like '%komoona%'
 group by placement_id,"time") a
 where obligated_cost_value > 0 ; 
 `

rssql(query, function cb(err, result) {
  if (err) {
    return console.error(err);
  }
  var nrows= result.rows.length;
  console.log(moment().format('HH:mm:ss')+': ' +nrows + ' rows returned.');
  for (var i=0; i<nrows; i++) 
  {
      var row = result.rows[i];
      row.time = moment(row.time).format('YYYY-MM-DD HH:mm:ss');  
      row.latest_entry = moment(row.latest_entry).format('YYYY-MM-DD HH:mm:ss');  
      writer.write(row);
  }
  writer.end();
  a.end();
});



console.log(moment().format('HH:mm:ss')+': started query ' +query.substr(0,20)+'... ');


