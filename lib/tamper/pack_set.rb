module Tamper
  class PackSet

    attr_accessor :metadata, :existence_pack

    def initialize
      @existence_pack = ExistencePack.new 
      @attr_packs = {}
      @metadata = {}
    end

    def add_attribute(attr_name, possibilities, max_choices)
      @attr_packs[attr_name] = Pack.build(attr_name, possibilities, max_choices)
    end

    def attributes
      @attr_packs.keys
    end

    def pack_for(attr)
      @attr_packs[attr]
    end

    def pack!(data, opts={})
      guid_attr = opts[:guid_attr] || 'id'
      max_guid  = opts[:max_guid]  || data.last[guid_attr]
      packs     = [@attr_packs.values, @existence_pack].flatten

      packs.each { |p| p.initialize_pack!(max_guid) }

      data.each do |d|
        packs.each { |p| p.encode(d[guid_attr], d) }
      end

      packs.each { |p| p.finalize_pack! }
    end

    def to_json(opts={})
      output = {
        existence: @existence_pack.to_h,
        attributes: @attr_packs.values.map { |p| p.to_h }
      }

      output.merge!(metadata)
      output.to_json
    end

  end
end