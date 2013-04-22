require 'spec_helper'
describe Tamper::Pack do

  describe ".build" do

    # Some sample scenarios...
    describe "with a large number of possibilities" do
      it "creates a BitmapPack when there are a large number of cohices allowed" do
        Tamper::Pack.build(:category_id, (0...50).to_a, 50).should be_a(Tamper::BitmapPack)
      end

      it "creates an IntegerPack when only a single choices is allowed" do
        Tamper::Pack.build(:category_id, (0...50).to_a, 1).should be_a(Tamper::IntegerPack)
      end
    end
  end

end