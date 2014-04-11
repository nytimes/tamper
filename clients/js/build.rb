require 'yui/compressor'

VERSION = '1.0.0'

compressor = YUI::JavaScriptCompressor.new

src = File.read('src/tamper.js')
src.gsub!(%r|/\* ---- begin test .+ ---- end test harness ---- \*/|m,'')

output = compressor.compress(src)
File.open("dist/tamper-#{VERSION}.js", 'w') { |f| f.write(src) }
File.open("dist/tamper-#{VERSION}-min.js", 'w') { |f| f.write(output) }