require 'spec_helper'

describe Tamper::IntegerPack do

  before do
    @data = [
      { 'id' => 0, 'category_id' => '14' },
      { 'id' => 1, 'category_id' => '21' },
      { 'id' => 2, 'category_id' => '46' },
    ]

    @possibilities = (0...50).to_a.map(&:to_s)

    @pack_set = Tamper::PackSet.new
    @pack_set.add_attribute(attr_name: :category_id,
                            possibilities: @possibilities,
                            max_choices: 1)
    @pack_set.pack!(@data)

    @category_pack = @pack_set.pack_for(:category_id)
    @category_pack.should be_a(Tamper::IntegerPack)
  end

  its "bit_window_width is equal to the number of bits required to represent the max possibility id" do
    @category_pack.bit_window_width.should == @possibilities.length.to_s(2).length
  end

  its "item_window_width is to the bit_window_width" do
    @category_pack.item_window_width.should == @category_pack.bit_window_width
  end

  its "overall length is equal to the item_window_width * number of items" do
    @category_pack.bitset.size.should == @category_pack.item_window_width * 3 + 32 + 8
  end

  it "encodes the length at the front of the pack" do
    @category_pack.bitset.to_s[0,32].to_i(2).should == 2
    @category_pack.bitset.to_s[32,8].to_i(2).should == 2
  end


  it "encodes the choice id in binary for each item" do
    str_bits = @category_pack.bitset.to_s

    # first item should be packed to represent 14
    str_bits[40,6].should == 14.to_s(2).rjust(6, '0')

    # next 21
    str_bits[46,6].should == 21.to_s(2).rjust(6, '0')

    # last item should be packed to represent 46
    str_bits[52,6].should == 46.to_s(2).rjust(6, '0')
  end

end