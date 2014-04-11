var tamper = require("../tamper.js")
var fs = require('fs')
var sys = require('sys')
var _ = require('underscore')

exports.testLargeJson = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/large.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 10, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[1,2,3,4,5,11,12,13,14,15],"Unpacks the correct guids of a consecutive sequence")
        test.deepEqual(_(seeds).pluck("bmp"),[["a"],["b","c"],["a","d","e","g","h"],["b"],["g","h"],["a"],["b","c"],["a","d","e","g","h"],["b"],["g","h"]],"Unpacks the bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("unbmp"),[["left"],["left"],["up","down"],["right"],["down"],["left"],["left"],["up","down"],["right"],["down"]],"Unpacks the unaligned bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("gender"),["male","female","male","female","male","male","female","male","female","male"],"Unpacks single-option integer packs correctly")
        test.deepEqual(_(seeds).pluck("num"),[["1"],["1"],["4"],["7"],["10"],["1"],["1"],["4"],["7"],["10"]],"Unpacks single-option integer packs correctly")
        test.done();
    });
};

exports.testSmallJson = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/small.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 2, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[1,2],"Unpacks the correct guids of a consecutive sequence")
        test.deepEqual(_(seeds).pluck("bmp"),[["a"],["b","c"]],"Unpacks the bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("unbmp"),[["left"],["left"]],"Unpacks the unaligned bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("gender"),["male","female"],"Unpacks single-option integer packs correctly")
        test.deepEqual(_(seeds).pluck("num"),[["1"],["1"]],"Unpacks single-option integer packs correctly")
        test.done();
    });
};

exports.testSmall2Json = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/small2.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 2, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[0,10],"Unpacks the correct guids of a consecutive sequence")
        test.deepEqual(_(seeds).pluck("bmp"),[["a"],["b","c"]],"Unpacks the bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("unbmp"),[["left"],["left"]],"Unpacks the unaligned bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("gender"),["male","female"],"Unpacks single-option integer packs correctly")
        test.deepEqual(_(seeds).pluck("num"),[["1"],["1"]],"Unpacks single-option integer packs correctly")
        test.done();
    });
};

exports.testSparseJson = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/sparse.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 5, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[1,2,300,400,500],"Unpacks the correct guids of a consecutive sequence")
        test.deepEqual(_(seeds).pluck("bmp"),[["a"],["b","c"],["a","d","e","g","h"],["b"],["g","h"]],"Unpacks the bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("unbmp"),[["left"],["left"],["up","down"],["right"],["down"]],"Unpacks the unaligned bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("gender"),["male","female","male","female","male"],"Unpacks single-option integer packs correctly")
        test.deepEqual(_(seeds).pluck("num"),[["1"],["1"],["4"],["7"],["10"]],"Unpacks single-option integer packs correctly")
        test.done();
    });
};

exports.testSparseStartJson = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/spstart.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 5, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[100,101,102,400,401],"Unpacks the correct guids of a consecutive sequence")
        test.deepEqual(_(seeds).pluck("bmp"),[["a"],["b","c"],["a","d","e","g","h"],["b"],["g","h"]],"Unpacks the bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("unbmp"),[["left"],["left"],["up","down"],["right"],["down"]],"Unpacks the unaligned bitmap pack correctly")
        test.deepEqual(_(seeds).pluck("gender"),["male","female","male","female","male"],"Unpacks single-option integer packs correctly")
        test.deepEqual(_(seeds).pluck("num"),[["1"],["1"],["4"],["7"],["10"]],"Unpacks single-option integer packs correctly")
        test.done();
    });
};

exports.testRunJson = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/run.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 45, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,400,401],"Unpacks the correct guids of a consecutive sequence at the head")
        test.done();
    });
};

exports.testRun2Json = function(test){
    t = tamper.Tamper();
    var data, seeds;
    fs.readFile("../../../test/canonical-output/run2.json", 'utf8', function (err, data) {
        data = JSON.parse(data);
        seeds = t.unpackData(data);
        test.equal(seeds.length, 87, "Unpacks the correct number of items")
        test.deepEqual(_(seeds).pluck("guid"),[98,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442],"Unpacks the correct guids of a consecutive sequence after a bitmap")
        test.done();
    });
};