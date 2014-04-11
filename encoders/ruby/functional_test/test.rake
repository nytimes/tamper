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

  desc "Generate functional outputs for this gem using the test inputs."
  task :generate do
    base_path  = File.dirname(__FILE__)
    config     = JSON.parse(File.read(File.join(base_path, 'config.json')), symbolize_names: true)
    inputs     = Dir.glob(File.join(base_path, '..', '..', '..', 'test', 'datasets', '*.json'))
    output_dir = File.join(base_path, 'output')

    FileUtils.mkdir_p(output_dir)

    puts
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

  desc "Each tamper generator should have a folder in functional_test/output.  Run this to diff output from the different systems."
  task :compare do
    base_path     = File.dirname(__FILE__)
    reference_dir = 
    output_files  = Dir.glob(File.join(base_path, 'output', '**/*.json'))
    tests         = output_files.map { |f| File.basename(f) }.uniq.sort

    tests.each do |test_file|
      outputs_to_test = output_files.select { |f| f.match(test_file) }

      puts "\nResults for: #{test_file}"
      baseline = outputs_to_test.shift
      baseline_name = baseline.split('/')[-2]

      puts "#{baseline_name} as baseline."
      baseline_data = JSON.parse(File.read(baseline))

      outputs_to_test.each do |test_file|
        test_name = test_file.split('/')[-2]
        puts "  vs. #{test_name}"
        test_data = JSON.parse(File.read(test_file))

        diff('existence', baseline_name, baseline_data['existence']['pack'], test_name, test_data['existence']['pack'])

        baseline_data['attributes'].each do |baseline_attr|
          test_attr = test_data['attributes'].detect { |attr| attr['attr_name'] == baseline_attr['attr_name'] }
          test_attr.delete('max_guid')
          baseline_attr.delete('max_guid')
          diff(baseline_attr['attr_name'], baseline_name, baseline_attr, test_name, test_attr)
        end
      end
    end
  end

  def diff(attr_name, file1, var1, file2, var2)
    if var1 == var2
      puts "    #{attr_name} is the same."
    else
      puts "    ERROR on #{attr_name}!\n    #{file1} was #{var1}\n    but #{file2} was #{var2}"
    end
  end

end