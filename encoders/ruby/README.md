# Tamper Ruby encoder

To encode data from ruby:

  * Create a new `Tamper::PackSet`.
  * Define attributes that should be packed with `PackSet#add_attribute`
  * Dump the pack as JSON with `PackSet#to_json`

### Init

```ruby
@pack_set = Tamper::PackSet.new
```

### Setting metadata on the pack

This metadata is only necessary if you're buffing attributes,
or your application requires extended info about the pack.

```ruby
@pack_set.meta = {
  buffer_url: "http://",
  buffer_callback: 'getDetails'
}
```

### Adding a packed attribute

These are the required attributes, you can set additional
keys if required by your application:

```ruby
@pack_set.add_attribute(
  name: :bucket,
  possibilities: @project.buckets.map(&:downcase),
  max_choices: 1
)
```

### Adding a buffered attribute

```ruby
@pack_set.add_buffered_attribute(
  name: 'name'
)
```

### Encoding data

#### If you can provide an array of hashes upfront


```ruby
# Keys can be either symbols or strings 
data = [{ 'id' : '1', 'zip_code' : '06475' }, { 'id' : '1', 'zip_code' : '91647' }]

@pack_set.pack!(data)
```

#### If you need to iterate (for example when doing a find_in_batches)

```ruby
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

### Outputting pack

```ruby
puts @pack_set.to_json
```

### For more info

See [protocol specs](https://github.com/newsdev/tamper/wiki/Packs) on the Tamper wiki.

### Running tests

ruby-tamper ships with:

  * rspecs, which can be run with `bundle exec rspec`
  * functional tests to generate output based on reference datasets.  Results are compared to the canonical-output in the root of the project. Run these with `bundle exec rake functional:test`