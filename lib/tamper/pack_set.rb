module Tamper
  class PackSet

    def initialize
      @packs = {}
    end

    def add_attribute(attr_name, possibilities, max_choices=1)
      @packs[attr_name] = Pack.build(attr_name, possibilities, max_choices)
    end

    def attributes
      @output.keys
    end

    def pack_for(attr)
      @packs[attr]
    end

    def pack!(data, guid_attr:'id')
      max_guid = data.last[guid_attr]

      @packs.values.each { |p| p.initialize_pack!(max_guid) }

      data.each do |d|
        @packs.values.each { |p| p.encode(d[guid_attr], d) }
      end
    end

    def to_json
      @packs.map { |p| p.to_h }.to_json
    end

  end
end