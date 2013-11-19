## Using tamper


### Init
```
@pack_set = Tamper::PackSet.new
```

### Setting metadata

```
@pack_set.meta = {
  buffer_url: "http://",
  buffer_callback: 'getDetails',
  default_thumb: 'thumb_url',
  default_oneup: 'large_image_url'
}
```

### Adding a packed attribute

```
@pack_set.add_attribute(
  name: :bucket,
  possibilities: @project.buckets.map(&:downcase),
  max_choices: 1,
  filter_type: 'primary_status',
  display_type: 'string',
  display_name: 'Bucket'
)
```


### Adding a buffered attribute

```
@pack_set.add_buffered_attribute(
  name: 'name',
  display_name: 'Submitter Name',
  num_choices: 1,
  filter_type: 'none',
  read_only: false,
  display_type: 'string'
)
```

### Actually packing the data

#### If you can provide an array of hashes upfront (keys can be either symbols or strings)
```
data = [{ 'id' : '1', 'zip_code' : '06475' }, { 'id' : '1', 'zip_code' : '91647' }]
@pack_set.pack!(data)
```

#### If you need to iterate (for example when doing a find_in_batches)
```
@pack_set.build_pack(max_guid: max_guid) do |pack|
  photo.each do |p|
    pack << {
      id: p.serial,
      bucket: p.submission.bucket,
      zip_code: p.zip_code,
      state: p.submitter.state
    }
  end
end
```

### Return .to_json and you should have a complete pack!
```
render :json => @pack_set.to_json

## The format

### Existence

8-bit control code:
0 (00000000): keep
1 (00000001): skip


Then for keep blocks:

32-bit unsigned int - length in bytes
8-bit unsigned int - remainder bits (0-7)

Data follows. Always encoded in 8-bit blocks.  If there is a remainder, right pad with zeroes.

For each position in a keep block, 1 means keep 0 means skip.

For skip blocks (always > 40 guid difference):

32-bit unsigned int - number of guids to skip


Example:

```
  To encode the existence of: 
    [0,1,2,3,6,10,12,14,16,17,18,19,20,21,22,23,25,31,32,97]

  We produce:

    00000000 00000000 00000000 00000000 00000100 00000001
    11110010 00101010 11111111 01000001 10000000 00000001
    00000000 00000000 00000000 01000000 00000000 00000000 
    00000000 00000000 00000000 00000001 10000000  

| KEEP CODE | 32-bit uint (keep 4 bytes)          | 
  00000000    00000000 00000000 00000000 00000100   
| 8bit uint (1 bit remainder) | 
  00000001   
| 4-byte + 1 bit existence bitmap (0,1,2,3,6,10,12,14,16,17,18,19,20,21,22,23,25,31,32,97)
  11110010 00101010 11111111 01000001 1|
| Right padding |
  0000000

| SKIP CODE | 32-bit uint - number of guids to skip (skip 33-96) |
  00000001    00000000 00000000 00000000 01000000   


| KEEP CODE | 32-bit uint (keep 0 bytes)          | 
  00000000    00000000 00000000 00000000 00000000   
| 8bit uint (1 bit remainder) | 
  00000001   
| 1-bit existence bitmap (98) |
  1
| Right padding |
  0000000
```

TODO: continguous range control code