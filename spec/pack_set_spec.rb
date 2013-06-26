require 'spec_helper'

describe Tamper::PackSet do
  before do
    @data = [
      { 'id' => 0, 'category_id' => '14' },
      { 'id' => 1, 'category_id' => '21' },
      { 'id' => 2, 'category_id' => '46' },
    ]

    @possibilities = (0...50).to_a.map(&:to_s)

    @pack_set = Tamper::PackSet.new(default_thumb: 'thumb_url')
    @pack_set.add_attribute(name: :category_id,
                            possibilities: @possibilities,
                            max_choices: 1,
                            filter_type: 'category')
  end

  it "packs data using a block" do
    @pack_set.build_pack(max_guid: 2) do |p|
      @data.each { |d| p << d }
    end

    @pack_set.existence_pack.bitset.to_s[-3,3].should == '111'
  end

  it "saves additional attributes as pack.meta" do
    @pack_set.pack_for(:category_id).meta.should == { filter_type: 'category' }
  end

  it "includes metadata passed at init as a top-level attribute in JSON" do
    @pack_set.to_json[:default_thumb].should == 'thumb_url'
  end

  it "can pack unordered data using a block" do
    @data.first['id'] = 4

    @pack_set.build_unordered_pack(max_guid: 4) do |p|
      @data.each { |d| p << d }
    end

    @pack_set.existence_pack.bitset.to_s[-5,5].should == '01101'
  end

  it "includes buffered attrs as part of the JSON attributes array" do
    @pack_set.add_buffered_attribute(
      name: 'caption',
      display_name: 'Display Caption',
      filter_type: 'none'
    )

    caption_attr = @pack_set.to_json[:attributes][:caption]
    caption_attr.should_not be_nil
    caption_attr[:display_name].should == 'Display Caption'
  end

end