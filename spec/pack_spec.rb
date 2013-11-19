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

end