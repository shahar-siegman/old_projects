"use strict"
const through = require('through')

var t1 = through()
var t2 = through()
t1.pipe(t2).pipe(process.stdout)

for (var i=0; i<10; i++) 
    t1.queue('hello')
t2.queue('world')

setTimeout(function () { 1 }, 1500)