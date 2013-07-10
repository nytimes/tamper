## Using tamper

```
@pack_set = Tamper::PackSet.new

# Setting metadata
@pack_set.meta = {
  buffer_url: "http://",
  buffer_callback: 'getDetails',
  default_thumb: 'thumb_url',
  default_oneup: 'large_image_url'
}

# Adding a packed attribute
@pack_set.add_attribute(
  name: :bucket,
  possibilities: @project.buckets.map(&:downcase),
  max_choices: 1,
  filter_type: 'primary_status',
  display_type: 'string',
  display_name: 'Bucket'
)


# Adding a buffered attribute
@pack_set.add_buffered_attribute(
  name: 'name',
  display_name: 'Submitter Name',
  num_choices: 1,
  filter_type: 'none',
  read_only: false,
  display_type: 'string'
)


# Actually packing the data if you can provide an array of hashes upfront (keys can be either symbols or strings)
data = [{ 'id' : '1', 'zip_code' : '06475' }, { 'id' : '1', 'zip_code' : '91647' }]
@pack_set.pack!(data)

# Actually packing the data, if you need to iterate (for example when doing a find_in_batches)
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


# Return .to_json and you should have a complete pack!
render :json => @pack_set.to_json
```