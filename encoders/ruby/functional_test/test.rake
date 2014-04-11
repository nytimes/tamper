require 'json'
require 'tamper'

# The test/datasets folder at the root of the project
# contains a variety of reference datasets.
#
# `rake functional:generate` will write generate tamper output for each
# test file and write the result to output/ruby-tamper.
#
# Use `rake functional:compare` to compare the outputs to the canonical version.
namespace :functional do

  desc "Generate functional outputs, then compare them"
  task :test do
    Rake::Task["functional:generate"].invoke
    Rake::Task["functional:compare"].invoke
  end

  desc "Generate functional outputs for this gem using the test inputs."
  task :generate do
    base_path  = File.dirname(__FILE__)
    config     = JSON.parse(File.read(File.join(base_path, 'config.json')), symbolize_names: true)
    inputs     = Dir.glob(File.join(base_path, '..', '..', '..', 'test', 'datasets', '*.json'))
    output_dir = File.join(base_path, 'output')

    puts "Sweeping output dir..."
    FileUtils.rm_f(File.join(output_dir, '*.json'))
    FileUtils.mkdir_p(output_dir)

    puts "Generating test output for ruby-tamper."

    inputs.each do |input_file|
      print "Packing #{File.basename(input_file)}... "
      @pack_set = Tamper::PackSet.new
      config[:attrs].each { |attr| @pack_set.add_attribute(attr) }

      begin
        data = JSON.parse(File.read(input_file))
        @pack_set.pack!(data['items'], guid_attr: 'guid')
        puts "Success!"
      rescue Exception => e
        puts; puts "ERROR: #{e.class} #{e.message}"
        puts e.backtrace.select { |l| l.match('lib/tamper') }.join("\n")
        exit(1)
      end

      File.open(File.join(output_dir, File.basename(input_file)), 'w') { |f| f.write(@pack_set.to_json) }
    end
  end

  desc "Run this to diff output vs. canonical outputs."
  task :compare do
    base_path     = File.dirname(__FILE__)
    reference_dir = File.join(base_path, '..', '..', '..', 'test', 'canonical-output')
    output_files  = Dir.glob(File.join(base_path, 'output', '*.json'))
    diffs = []
    
    output_files.each do |test_output|
      test_file = File.basename(test_output)

      puts "\nResults for: #{test_file}"
      reference_data = JSON.parse(File.read(File.join(reference_dir, test_file)))

      ruby_data = JSON.parse(File.read(test_output))

      diffs << diff('existence', reference_data['existence']['pack'], ruby_data['existence']['pack'])

      reference_data['attributes'].each do |reference_attr|
        ruby_attr = ruby_data['attributes'].detect { |attr| attr['attr_name'] == reference_attr['attr_name'] }
        ruby_attr.delete('max_guid')
        reference_attr.delete('max_guid')
        diffs << diff(reference_attr['attr_name'], reference_attr, ruby_attr)
      end
    end

    puts
    if diffs.any? { |d| d == false }
      puts "**** There were errors in this test run."
    else
      puts "Functional tests OK!"
    end
  end

  # Returns true if values were the same, false otherwise.
  def diff(attr_name, var1, var2)
    if var1 == var2
      puts "    #{attr_name} is the same."
      return true
    else
      puts "    ERROR on #{attr_name}!\n    reference was #{var1}\n    but ruby was #{var2}"
      return false
    end
  end

end