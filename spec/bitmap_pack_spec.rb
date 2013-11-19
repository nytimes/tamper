require 'spec_helper'

describe Tamper::BitmapPack do

  before do
    @data = [
      { 'id' => 0, 'color' => ['yellow','blue'] },
      { 'id' => 1, 'color' => ['blue', 'yellow'] },
      { 'id' => 2, 'color' => ['red'] },
    ]

    @pack_set = Tamper::PackSet.new
    @pack_set.add_attribute(attr_name: :color,
                            possibilities: ['yellow', 'red', 'blue', 'purple'],
                            max_choices: 2)
    @pack_set.pack!(@data)

    @color_pack = @pack_set.pack_for(:color)
    @color_pack.should be_a(Tamper::BitmapPack)
  end

  its "item_window_width is equal to the number of possibilities, since multiple bits can be flipped for each item" do
    @color_pack.item_window_width.should == ['yellow','red','blue','purple'].length
  end

  its "length is equal to the number of choices * the number of items" do
    @color_pack.bitset.size.should == (4 * 3) + 32 + 8
  end

  it "encodes the length at the front of the pack" do
    @color_pack.bitset.to_s[0,32].to_i(2).should == 1
    @color_pack.bitset.to_s[32,8].to_i(2).should == 4
  end

  it "flips a bit true for each selected choice" do
    str_bits = @color_pack.bitset.to_s

    # first item should have idx 0 set to true since it's yellow, idx 2 since it's blue
    str_bits[40,4].should == '1010'

    # second item should have the same, order that possibilities are in does not matter
    str_bits[44,4].should == '1010'

    # last item should have pos 2 set to true since it's red
    str_bits[48,4].should == '0100'
  end

end
