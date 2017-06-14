"use strict"
const through = require('through')
const Readable = require('stream').Readable

var sequence= new Readable({objectMode: true});
var i =0 ;
sequence._read = function() {
    var self = this;
    setTimeout(function() { self.push(i); i++ }, 500)
}

sequence.pipe(through(function(data) { 
    console.log(data)
    var self= this;
    if (data ==10) {
        self.pause();
        setTimeout(function() {
            console.log('resume!');
            self.resume()}, 2500)
    }
        
}))
