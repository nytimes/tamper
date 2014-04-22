require 'json'
require 'open-uri'
require 'tamper'

# Paste an Article Search API key from http://developer.nytimes.com/apps/mykeys
API_KEY = '...'

query_url = "http://api.nytimes.com/svc/search/v2/articlesearch.json?api-key=#{API_KEY}"

# Grab articles from the API
articles = []
(0...40).each do |idx|
  req_url = query_url + "&page=#{idx}"
  res = JSON.parse(open(URI.escape(req_url)).read)

  puts "Crawled page #{idx + 1}."
  articles += res['response']['docs']
end

# Kill invalid bylines.
articles.delete_if { |a| !a['byline'].is_a?(Hash) }

# Assign each a numeric ID.  If we were storing these in a database,
# we could assign an autoincrement id.  For this demo we'll assign a
# temporary id.
#
# A numeric id is required when generating a Tamper pack.
articles.each_with_index { |a, idx| a.merge!(id: idx)}

# Generate the distinct possibilities for each attributes.
# If we were storing these in a db, we could use a DISTINCT query.
possibilities = {
  section_name: articles.map { |a| a['section_name'] }.compact.uniq.sort,
  byline: articles.map { |a| a['byline']['original'] }.compact.uniq.sort
}

# Configure pack
pack = Tamper::PackSet.new

pack.add_attribute(
  attr_name: :byline,
  possibilities: possibilities[:byline],
  max_choices: 1,
  filter_type: 'category'
)

pack.add_attribute(
  attr_name: :section_name,
  possibilities: possibilities[:section_name],
  max_choices: 1,
  filter_type: 'category'
)

pack.build_pack(num_items: articles.length, max_guid: articles.last[:id]) do |pack|
  articles.each do |a|
    pack << {
      id: a[:id],
      section_name: a['section_name'],
      byline: a['byline']['original']
    }
  end
end

puts "\n" * 3
puts "Tamper pack:"
puts pack.to_json
