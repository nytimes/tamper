require 'tamper'
require 'open-uri'
require 'fileutils'
require 'csv'

# In this example, we pack the state and DMA name for a list of U.S. cities.
#
# When using PourOver, we would normally buffer (lazy-load) the City Name.
# On page load we would draw filters; as the user interacts we would load
# in the city names as well as other attrs (say, a map).
# Factoring the city name out, the 744k input compresses to 45k.
#
# If we include the city name in the pack,
# size of the compressed output increases to 200kb.

def size_in_kb(file_path)
  '%0.1f kb' % (File.size(file_path) / 1024.0)
end

# This borrows DMA data from Google AdWords, see:
# https://developers.google.com/adwords/api/docs/appendix/cities-DMAregions
DMA_CSV   = 'https://goo.gl/itBaJE'
DATA_FILE = File.join(File.dirname(__FILE__), 'tmp', 'city_data.csv')

# Cache Google data locally if we haven't yet done so.
if !File.exists?(DATA_FILE)
  FileUtils.mkdir_p(File.dirname(DATA_FILE))
  print "Downloading data... "
  File.open(DATA_FILE, 'w') { |f| f.write(open(DMA_CSV).read ) }
  puts "Done!"
end

data = CSV.read(DATA_FILE, headers: true)
possibilties = {
  states: [],
  dmas: [],
  cities: []
}
max_id = 0


# Generate the distinct possibilties for each attributes.
# If we were storing these in a db, we could use a DISTINCT query.
print "Generating possibilties... "
data.each do |row|
  dma   = row['DMA Region Name']
  state = dma.split(',').last.strip
  guid  = row['Criteria ID'].to_i

  possibilties[:states] << state
  possibilties[:dmas]   << dma
  possibilties[:cities] << row['City Name']
  max_id = guid if guid > max_id
end
possibilties.each { |k, v| v.uniq! }
puts "Done!"

# Also, sort the data. Currently tamper requires data to be sorted by guid.
data = data.sort_by { |row| row['Criteria ID'].to_i }

# Configure pack
pack = Tamper::PackSet.new

pack.add_attribute(
  attr_name: :state,
  possibilities: possibilties[:states],
  max_choices: 1
)

pack.add_attribute(
  attr_name: :dma,
  possibilities: possibilties[:dmas],
  max_choices: 1
)

print "Packing data... "
pack.build_pack(num_items: data.length, max_guid: max_id) do |pack|
  data.each do |row|

    dma   = row['DMA Region Name']
    state = dma.split(',').last.strip
    guid  = row['Criteria ID'].to_i

    pack << {
      id: guid,
      state: state,
      dma: dma
    }
  end
end
puts "Done!"

pack_file = 'tmp/pack.json'
File.open(pack_file, 'w') { |f| f.write(pack.to_json) }

print "Gzipping ouput... "
`gzip -9 -k #{DATA_FILE}`
`gzip -9 -k #{pack_file}`
puts "Done!"

puts "\n" * 3
puts "Tamper pack:"
puts pack.to_json


puts "\n" * 2
puts "Raw:"
puts "Original file was: #{size_in_kb(DATA_FILE)}"
puts "Pack is #{size_in_kb(pack_file)}"

puts
puts "Gzipped:"
puts "Original file was: #{size_in_kb(DATA_FILE + '.gz')}"
puts "Pack is #{size_in_kb(pack_file + '.gz')}"

FileUtils.rm(Dir.glob("tmp/*.gz"))