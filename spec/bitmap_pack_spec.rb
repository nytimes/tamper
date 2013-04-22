require 'spec_helper'
describe Tamper::BitmapPack do

  describe "for multiple-choice data" do

    before do
      @data = [
        { 'id' => 0, 'color' => ['yellow','blue'] },
        { 'id' => 1, 'color' => ['blue', 'yellow'] },
        { 'id' => 2, 'color' => ['red'] },
      ]

      @pack_set = Tamper::PackSet.new
      @pack_set.add_attribute(:color, ['yellow', 'red', 'blue', 'purple'], 2)
      @pack_set.pack!(@data)

      @color_pack = @pack_set.pack_for(:color)
      @color_pack.should be_a(Tamper::BitmapPack)
    end

    its "item_window_width is equal to the number of possibilities, since multiple bits can be flipped for each item" do
      @color_pack.item_window_width.should == ['yellow','red','blue','purple'].length
    end

    its "length is equal to the number of choices * the number of items" do
      @color_pack.bitset.size.should == (4 * 3)
    end

    it "flips a bit true for each selected choice" do
      str_bits = @color_pack.bitset.to_s

      # first item should have idx 0 set to true since it's yellow, idx 2 since it's blue
      str_bits[0,4].should == '1010'

      # second item should have the same, order that possibilities are in does not matter
      str_bits[4,4].should == '1010'

      # last item should have pos 2 set to true since it's red
      str_bits[-4,4].should == '0100'
    end

  end

end
