module Tamper
  class PackSet

    attr_accessor :metadata, :existence_pack

    def initialize
      @existence_pack = ExistencePack.new 
      @attr_packs = {}
      @metadata = {}
    end

    def add_attribute(attr_name, possibilities, max_choices=1)
      @attr_packs[attr_name] = Pack.build(attr_name, possibilities, max_choices)
    end

    def attributes
      @output.keys
    end

    def pack_for(attr)
      @attr_packs[attr]
    end

    def pack!(data, guid_attr:'id')
      max_guid = data.last[guid_attr]
      packs = [@attr_packs.values, @existence_pack].flatten

      packs.each { |p| p.initialize_pack!(max_guid) }

      data.each do |d|
        packs.each { |p| p.encode(d[guid_attr], d) }
      end

      packs.each { |p| p.finalize_pack! }
    end

    def to_json
      output = {
        existence: @existence_pack.to_h,
        attributes: @attr_packs.map { |p| p.to_h }
      }

      output.merge!(metadata)
      output.to_json
    end

  end
end