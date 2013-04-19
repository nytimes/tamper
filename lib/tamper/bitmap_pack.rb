module Tamper
  class BitmapPack < Pack
    
    def encoding
      :bitmap
    end

    def encode(idx, data)
      choice_data = data[attr_name.to_s]
      choice_data = [choice_data] unless choice_data.is_a?(Array)

      item_offset = idx * item_window_width
      choice_data.each do |choice|
        choice_offset = possibilities.index(choice).to_i
        @bitset[item_offset + choice_offset] = true
      end
    end

    def initialize_pack!(max_guid)
      @item_window_width = possibilities.length
      @bitset = Bitset.new(item_window_width * (max_guid + 1))
    end

  end
end