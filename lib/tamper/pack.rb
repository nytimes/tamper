module Tamper
  class Pack
    attr_reader :attr_name, :possibilities, :max_choices, :encoding, :bitset

    attr_reader :bit_window_width, :item_window_width, :bitset

    attr_reader :max_guid

    attr_accessor :meta

    def initialize(attr_name, possibilities, max_choices)
      @attr_name, @possibilities, @max_choices = attr_name, possibilities, max_choices
      @meta = {}

      raise ArgumentError, "Possibilities are empty for #{attr_name}!" if possibilities.nil? || possibilities.empty?
    end

    def self.build(attr_name, possibilities, max_choices)
      if (max_choices * Math.log2(possibilities.length)) < possibilities.length
        pack = IntegerPack
      else
        pack = BitmapPack
      end

      pack.new(attr_name, possibilities, max_choices)
    end

    def to_h
      output = { encoding: encoding,
                attr_name: attr_name,
                possibilities: possibilities,
                pack: encoded_bitset,
                item_window_width: item_window_width,
                bit_window_width: bit_window_width,
                max_choices: max_choices }
      output.merge(meta)
    end

    # Most packs do not implement this.
    def finalize_pack!
      data = @bitset.to_s

      byte_length = data.length / 8
      remaining_bits = data.length % 8

      output  = byte_length.to_s(2).rjust(32)
      output += remaining_bits.to_s(2).rjust(8)
      output += data

      @bitset = Bitset.from_s(output)
    end

    # def padded_output
    #   length = @bitset.to_s.length

    #   pad_length = 8 - (length % 8)
    #   pad_set = Bitset.new(pad_length)
    #   pad_set[pad_length - 1] = true

    #   Bitset.from_s(pad_set.to_s + @bitset.to_s)
    # end

    private
    def encoded_bitset
      Base64.strict_encode64(@bitset.to_s.marshal_dump[:data]) if @bitset
    end
  end
end