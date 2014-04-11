---
layout: post
title: Introducing Tamper
---

### What is Tamper?

Tamper is a serialization protocol for categorical data.  It achieves high compression ratios by finding the smallest possible binary representation for each category.

### How does it work?

Take, for example, a boolean attribute.  In naïve JSON we would represent this as a string, "true" or "false":

```json
[{
  "guid" : 1,
  "edpick" : true
},
{
  "guid" : 1,
  "edpick" : false
}]
```

Each value is 4-5 bytes; including punctuation **27 bytes are required per item**.

Tamper evaluates the data to find the most efficent encoding&mdash;in this case, a [BitmapPack]({{ site.github.wiki }}/Packs/#bitmap-pack).

The data is serialized as `10`, **just 0.25 bytes!**

Full details of Tamper's encoding scheme are in the [protocol docs](Packs).

----

### How do I get started?

Tamper is intended as a companion to [pourover.js](http://newsdev.github.io/pourover/), but can be used independently.

You'll need:

  1. an encoder to write the TamperPack (available for [Ruby](RubyEncoder), and soon Go)
  2. the [javascript client](JavascriptClient).


---

#### How does Tamper compare to other serialization approaches?

##### gzipped JSON

Gzip works by [writing backreferences to previous symbols](http://en.wikipedia.org/wiki/DEFLATE).  Each time a symbol is repeated, gzip encodes the location and length of the backreference.  These references are in turn compressed &mdash; but in most real-world applications are larger than a direct binary encoding.

Additionally, conventional array-of-object JSON layouts generate backreferences at each attribute boundary.  Because Tamper packs all values for an attribute in a fixed-width format, there is no attribute boundary overhead.

##### Google Protocol Buffers

Integer packs are similar in concept to [Protocol Buffer varints](https://developers.google.com/protocol-buffers/docs/encoding#varints): integer size is dynamically scaled to fit the value rather than being fixed at 32 bits.  However, the minimum size of a varint is one byte; for many applications Tamper only requires 2-5 bits for each item.

Protocol Buffers are optimized for messaging details of a particular item; Tamper packs optimize for bulk categorical loads of data for many items.

