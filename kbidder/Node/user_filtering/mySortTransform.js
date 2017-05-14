'use strict'
const Duplex = require('stream').Duplex;
const Transform = require('stream').Transform;
const batch = 20000;


class sort extends Transform {
    constructor(options, comp) {
        super(options);
        this.a = new Array(batch);
        this.i = 0;
        this.k = 0;
        this.currentSize = batch;
        this.isDone = false;
        this.sortedArray = undefined;
        this.comp = comp;
    }

    _transform(data, _, callback) {
        if (data) {
            this.a[this.i++] = data;
            if (this.i == this.currentSize) {
                this.currentSize = this.currentSize * 2;
                var tmp = new Array(this.currentSize);
                for (var j = 0; j < this.i; j++)
                    tmp[j] = this.a[j];
                this.a = tmp;
            }
        }
        callback();
    }

    _flush() {
        this.sortedArray = this.a.slice(0, this.i).sort(this.comp);
        var self = this
        this.fullflush();
    }

    fullflush() {
        while (this.k < this.i)
            this.push(this.sortedArray[this.k++]);
        this.push(null)
    }
}


function start(comp) {
    return new sort({ objectMode: true }, comp)
}
module.exports = start;
