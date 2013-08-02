require 'spec_helper'
describe Tamper::Pack do

  describe ".build" do

    # Some sample situations...
    describe "with a large number of possibilities" do
      it "creates an IntegerPack when only a single choice is allowed" do
        Tamper::Pack.build(:category_id, (0...50).to_a, 1).should be_a(Tamper::IntegerPack)
      end

      it "creates a BitmapPack when there are a large number of choices allowed" do
        Tamper::Pack.build(:category_id, (0...50).to_a, 50).should be_a(Tamper::BitmapPack)
      end
    end
  end

  describe ".padded_output with a length not evenly divisible into bytes" do
    before do
      @data = [
        { 'id' => 1 },
        { 'id' => 2 },
        { 'id' => 3 },
        { 'id' => 4 },
        { 'id' => 5 }
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.pack!(@data)

      @existence_pack = @pack_set.existence_pack
      @existence_pack.should be_a(Tamper::ExistencePack)
      @output = @existence_pack.padded_output
    end

    it "pads the set out to be an even number of bytes" do
      @output.to_s.length.should == 24
    end

    it "pads with 1s" do
      @output.to_s[0,1].should == '1'
    end
  end


end