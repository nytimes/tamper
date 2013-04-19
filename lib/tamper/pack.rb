module Tamper
  class Pack
    attr_reader :attr_name, :possibilities, :max_choices, :encoding, :bitset

    attr_reader :bit_window_width, :item_window_width, :bitset

    attr_reader :max_guid

    def initialize(attr_name, possibilities, max_choices=1)
      @attr_name, @possibilities, @max_choices = attr_name, possibilities, max_choices
      # @possibilities = @possibilities.insert(0, nil)
    end

    def self.build(attr_name, possibilities, max_choices=1)
      if (max_choices * Math.log2(possibilities.length)) > possibilities.length
       pack = IntegerPack
      else
        pack = BitmapPack
      end

      pack.new(attr_name, possibilities, max_choices)
    end

    def to_h
      { encoding: encoding,
        attribute: attr_name,
        possibilities: possibilities,
        pack: encoded_bitset,
        item_window_width: item_window_width,
        bit_window_width: bit_window_width }
    end

    private
    def encoded_bitset
      Base64.strict_encode64(@bitset.marshal_dump[:data])
    end
  end
end