require 'spec_helper'

describe Tamper::PackSet do
  before do
    @data = [
      { 'id' => 0, 'category_id' => '14' },
      { 'id' => 1, 'category_id' => '21' },
      { 'id' => 2, 'category_id' => '46' },
    ]

    @possibilities = (0...50).to_a.map(&:to_s)

    @pack_set = Tamper::PackSet.new
    @pack_set.add_attribute(:category_id, @possibilities, 1)
  end

  it "packs data using a block" do
    @pack_set.build_pack(max_guid: 2) do |p|
      @data.each { |d| p << d }
    end

    @pack_set.existence_pack.bitset.to_s[-3,3].should == '111'
  end

end