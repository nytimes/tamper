require 'spec_helper'
describe Tamper::BitmapPack do

  describe "for single-choice data" do

    before do
      @data = [
        { 'id' => 0, 'color' => 'yellow' },
        { 'id' => 1, 'color' => 'yellow' },
        { 'id' => 2, 'color' => 'red' },
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.add_attribute(:color, ['yellow', 'red', 'purple'], 1)
      @pack_set.pack!(@data)

      @color_pack = @pack_set.pack_for(:color)
    end

    its "item_window_width is equal to the number of choices" do
      @color_pack.item_window_width.should == ['yellow','red','purple'].length
    end

    its "length is equal to the number of choices * the number of items" do
      @color_pack.bitset.size.should == (3 * 3)
    end

    it "flips a bit true for each selected choice" do
      str_bits = @color_pack.bitset.to_s

      # first item should have pos 1 set to true since it's yellow
      str_bits[0,3].should == '100'

      puts str_bits.inspect
      # last item should have pos 2 set to true since it's red
      str_bits[-3,3].should == '010'
    end

  end
end
