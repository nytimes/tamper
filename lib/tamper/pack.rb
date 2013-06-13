module Tamper
  class Pack
    attr_reader :attr_name, :possibilities, :max_choices, :encoding, :bitset

    attr_reader :bit_window_width, :item_window_width, :bitset

    attr_reader :max_guid

    attr_accessor :meta

    def initialize(attr_name, possibilities, max_choices)
      @attr_name, @possibilities, @max_choices = attr_name, possibilities, max_choices
      @meta = {}
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
    end

    private
    def encoded_bitset
      Base64.strict_encode64(@bitset.marshal_dump[:data])
    end
  end
end