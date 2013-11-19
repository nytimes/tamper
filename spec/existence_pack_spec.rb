require 'spec_helper'

describe Tamper::ExistencePack do

  describe "with continguous ids" do
    before do
      @data = [
        { 'id' => 0 },
        { 'id' => 1 },
        { 'id' => 2 }
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.pack!(@data)

      @existence_pack = @pack_set.existence_pack
      @existence_pack.should be_a(Tamper::ExistencePack)
      @bits = @existence_pack.bitset.to_s
    end

    it "sets a control code at the start to keep all ids" do
      @bits[0,8].should == '00000000'
    end

    it "includes 0 bytes in existence bitmap" do
      @bits[8,32].to_i(2).should == 0
    end

    it "includes 3 remainder bits in existence bitmap" do
      @bits[40,8].to_i(2).should == 3
    end

    it "sets all ids as existing, then pads with zeroes" do
      @bits[48,8].should == '11100000'
    end

  end

  describe "with gaps in ids" do
    before do
      @data = [
        { 'id' => 0 },
        { 'id' => 1 },
        { 'id' => 2 },
        { 'id' => 6 },
        { 'id' => 60 },
        { 'id' => 61 },
        { 'id' => 62 },
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.pack!(@data)

      @existence_pack = @pack_set.existence_pack
      @existence_pack.should be_a(Tamper::ExistencePack)
      @bits = @existence_pack.bitset.to_s
    end

    it "keeps all ids with gaps < 20 in a contiguous set" do
      @bits[0,8].should == '00000000' # keep code
      @bits[8,32].to_i(2).should == 0 # keep 0 bytes of data
      @bits[40,8].to_i(2).should == 7 # keep 7 remainder bits
      @bits[48,8].to_s.should == '11100010' # encode 1-6
    end

    it "sets a skip control char if the gap is > 40" do
      @bits[56,8].should == '00000001'
      @bits[64,32].to_i(2).should == 53
    end

    it "sets a keep control char after the gap" do
      @bits[96,8].should == '00000000'  # keep
      @bits[104,32].to_i(2).should == 0  # keep 0 bytes
      @bits[136,8].to_i(2).should == 3   # keep 3 remainder bits
    end

    it "sets bits correctly after a skipped gap" do
      @bits[144,8].to_s.should == '11100000'
    end
  end

  describe "with a guid sequence that starts with a skip" do
    before do
      @data = [
        { 'id' => 100 },
        { 'id' => 101 },
        { 'id' => 102 }
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.pack!(@data)

      @existence_pack = @pack_set.existence_pack
      @existence_pack.should be_a(Tamper::ExistencePack)
      @bits = @existence_pack.bitset.to_s
    end

    it "sets a skip control code at the start of the set" do
      @bits[0,8].should == '00000001'  # skip
      @bits[8,32].to_i(2).should == 100 # skip 99 guids
    end
  end

  describe "the example from the README" do
    before do

      test_guids = [0,1,2,3,6,10,12,14,16,17,18,19,20,21,22,23,25,31,32,97]
      @data = test_guids.map { |guid| { 'id' => guid }}

      @pack_set = Tamper::PackSet.new
      @pack_set.pack!(@data)

      @existence_pack = @pack_set.existence_pack
      @existence_pack.should be_a(Tamper::ExistencePack)
      @bits = @existence_pack.bitset.to_s
    end

    it "works" do
      example_data = <<EOS
    00000000 00000000 00000000 00000000 00000100 00000001
    11110010 00101010 11111111 01000001 10000000 00000001
    00000000 00000000 00000000 01000000 00000000 00000000 
    00000000 00000000 00000000 00000001 10000000 
EOS
      example_data.gsub!(/[ \n]/, '')
      @bits.should == example_data
    end
  end

end