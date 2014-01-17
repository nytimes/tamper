module Tamper
  class BitmapPack < Pack

    def encoding
      :bitmap
    end

    def encode(idx, data)
      choice_data = data[attr_name.to_sym] || data[attr_name.to_s]
      choice_data = [choice_data] unless choice_data.is_a?(Array)

      item_offset = idx * item_window_width
      choice_data.each do |choice|
        choice_offset = possibilities.index(choice.to_s)
        @bitset[item_offset + choice_offset] = true if choice_offset
      end
    end

    def initialize_pack!(max_guid, num_items)
      @bit_window_width = 1
      @item_window_width = possibilities.length
      @bitset = Bitset.new(item_window_width * num_items)
    end

  end
end