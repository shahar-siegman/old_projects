var Redshift = require('node-redshift');
 
var client = {
  user: "master",
  database: "public",
  password: "ntxyrNtxyr77",
  port: 5439,
  host: "kmnspark.crc6oizgxxw8.us-east-1.redshift.amazonaws.com"
};
 
var redshiftClient = new Redshift(client);
module.exports = redshiftClient;

