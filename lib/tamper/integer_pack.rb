module Tamper
  class IntegerPack < Pack

    def encoding
      :integer
    end

    def encode(idx, data)
      choice_data = data[attr_name.to_sym] || data[attr_name.to_s]
      choice_data = [choice_data] unless choice_data.is_a?(Array)

      (0...max_choices).each do |choice_idx|
        choice_offset = (item_window_width * idx) + (bit_window_width * choice_idx)

        value = choice_data[choice_idx]

        # TODO: test and handle nil case
        if possibility_idx = possibilities.index(value.to_s)
          possibility_id =  possibility_idx + 1
        else
          possibility_id = 0
        end

        bit_code = possibility_id.to_i.to_s(2).split('') # converts to str binary representation
        bit_code_length_pad = bit_window_width - bit_code.length
        bit_code.each_with_index do |bit, bit_idx|
          @bitset[(choice_offset + bit_code_length_pad + bit_idx)] = bit == "1"
        end
      end

    end

    def initialize_pack!(max_guid, num_items)
      @bit_window_width = Math.log2(possibilities.length).ceil
      @bit_window_width = 1        if @bit_window_width == 0  # edge case: 1 possibility

      @item_window_width = bit_window_width * max_choices
      @bitset = Bitset.new(item_window_width * num_items)
    end

  end
end