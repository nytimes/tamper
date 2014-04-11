if (typeof module !== 'undefined' && module.exports) {
   var atob = require("../test/node_modules/atob"),
        _ =  require("../test/node_modules/underscore");
}

Tamper = {}
Tamper.biterate = function(encoded){
  var binary = atob(encoded),
      length = binary.length,
      i = 0,
      output = [];
  while(i < length){
    var b = binary.charCodeAt(i),
        j = 0;
    while(j < 8 ){
      output.push((b >> (7-j)) & 1);
      j++;
    }
    i++;
  }
  return output;
}

Tamper.unpackExistence = function(element,default_attrs){
  if(typeof(callback) === "undefined"){callback = false}
  var bitArray = Tamper.biterate(element.pack),
      length = bitArray.length,
      output = [],
      counter = 0,
      consumeCC = function(array){
        if(array.length < 2){throw "Improperly formatted bit array"}
        var cc = array.splice(0,8);
        cc = parseInt(cc.join(""),2)
        return cc;
      },
      consumeNum = function(n,array){
        var num = parseInt(array.splice(0,n).join(""),2);
        return num;
      },
      consumeChunk = function(bytes,bits,array){
        var num_bits = bytes*8 + bits,
            chunk = array.splice(0,bytes*8 + bits),
            i = 0;
        while(i < num_bits){
          if (!! chunk[i]){
            default_attrs = _.clone(default_attrs);
            output.push(_.extend(default_attrs,{guid: counter}));
          }
          counter++;
          i++;
        }
      },
      processBitArray = function(array){
        if(array.length === 0){
          return output;
        }
        var cc = consumeCC(array);
        if (cc == 0){
          var bytes_to_consume = consumeNum(32,array),
              bits_to_consume = consumeNum(8,array);
          consumeChunk(bytes_to_consume,bits_to_consume,array);
          if(bits_to_consume > 0){
            array.splice(0,8 - bits_to_consume)
          }
          return processBitArray(array);
        } else if (cc == 1){
          var num_to_skip = consumeNum(32,array);
          counter += num_to_skip;
          return processBitArray(array);
        } else if (cc == 2){
          var num_to_run = consumeNum(32,array);
          for (var i = 0;i < num_to_run;i++){
            default_attrs = _.clone(default_attrs);
            output.push(_.extend(default_attrs,{guid: counter}));
            counter = counter + 1;
          }
          return processBitArray(array);
        } else {
          throw "Unrecognized control code: " + cc;
        }
      };
  var ba = processBitArray(bitArray);
  return ba;
}

Tamper.unpackIntegerEncoding = function(element, num_items) {
  if(typeof(callback) === "undefined"){callback = false}
  var consumeNum = function(array,n){
        var num = parseInt(array.splice(0,n).join(""),2);
        return num;
      }
  var bitArray = Tamper.biterate(element.pack),
      bit_window_width = element.bit_window_width,
      item_window_width = element.item_window_width,
      item_chunks = item_window_width/bit_window_width;
      bytes_to_consume = consumeNum(bitArray,32),
      bits_to_consume = consumeNum(bitArray,8);
  var getPossibility = function(i){
    if(i === 0){
        return null
    } else {
        return element.possibilities[i - 1]
    }
  }
  var i = 0,output = [];

  while(i < num_items) {
    bit_window = bitArray.slice(i * item_window_width, (i * item_window_width) + item_window_width);
    var j = 0;
    while(j < item_chunks){
      var choice = bit_window.slice(j*bit_window_width,(j * bit_window_width) + bit_window_width);
      possibility_id = parseInt(choice.join(''), 2);
      if (! output[i]) {output[i] = []}
      var result = getPossibility(possibility_id);
      if(item_chunks == 1){ 
        output[i] = result
      } else if(result) {
        output[i].push(result);
      }
      j++;
    }
    i++;
  }

  return output;
}

Tamper.unpackBitmapEncoding = function(element){
  var consumeNum = function(array,n){
        var num = parseInt(array.splice(0,n).join(""),2);
        return num;
      }
  var bitArray = Tamper.biterate(element.pack),
      item_window_width = element.item_window_width,
      chunks = bitArray.length / item_window_width,
      bytes_to_consume = consumeNum(bitArray,32),
      bits_to_consum = consumeNum(bitArray,8);
  var i = 0,output = [];

  while(i < chunks) {
    bit_window = bitArray.slice(i * item_window_width, (i * item_window_width) + item_window_width);
    if (! output[i]) {output[i] = []}
    j = 0;
    while (j < item_window_width){
      if(bit_window[j] == "1"){
        output[i].push(element.possibilities[j]);
      }
      j++;
    }
    i++;
  }
  return output;

}

Tamper.unpackData = function(data,default_attrs){
  if(typeof(default_attrs) === "undefined"){var default_attrs = {}}
  if(data.existence){
    var exists = Tamper.unpackExistence(data.existence,default_attrs),collection;
    _(data.attributes).each(function(a){
      if(a.filter_type !== "category" && a.filter_type !== "primary_status" && a.filter_type !== "badge"){return;}
      if(a.encoding == "bitmap"){
        var attr_array = Tamper.unpackBitmapEncoding(a);
      } else if(a.encoding == "integer"){
        var attr_array = Tamper.unpackIntegerEncoding(a, exists.length);
      }
      _(exists).each(function(s,i){s[a.attr_name] = attr_array[i]});
    })
    return exists;
  } else {
    seeds = _(data.collection).map(function(i){var default_attrs = _.clone(default_attrs);return _(default_attrs).extend(i)});
    return seeds;
  }
}

if(typeof exports !== "undefined"){
    exports.Tamper = function(){
        return Tamper;
    }
}
