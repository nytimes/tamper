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
      @bits[0,2].should == '00'
      @bits[2,16].to_i(2).should == 3
    end

    it "sets all ids as existing" do
      @bits[-3,3].should == '111'
    end

  end

  describe "with gaps in ids" do
    before do
      @data = [
        { 'id' => 0 },
        { 'id' => 1 },
        { 'id' => 2 },
        { 'id' => 6 },
        { 'id' => 42 },
        { 'id' => 43 },
        { 'id' => 45 },
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.pack!(@data)

      @existence_pack = @pack_set.existence_pack
      @existence_pack.should be_a(Tamper::ExistencePack)
      @bits = @existence_pack.bitset.to_s
    end

    it "keeps all ids with gaps < 20 in a contiguous set" do
      @bits[0,2].should == '00' # keep code
      @bits[2,16].to_i(2).should == 7
    end

    it "sets ids that exist to 1, ids that don't to 0" do
      @bits[18,7].should == '1110001'
    end

    it "sets a skip control char if the gap is > 20" do
      @bits[25,2].should == '01'
      @bits[27,16].to_i(2).should == 35
    end

    it "sets a keep control char after the gap" do
      @bits[43,2].should == '00'
      @bits[45,16].to_i(2).should == 4
    end

    it "sets bits correctly after a skipped gap" do
      @bits[61,4].should == '1101'
    end
  end

  describe "with guids that don't begin at 0" do
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
      @bits[0,2].should == '01'
    end


  end


end