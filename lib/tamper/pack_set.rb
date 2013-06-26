module Tamper
  class PackSet

    attr_accessor :meta, :existence_pack

    def initialize
      @existence_pack = ExistencePack.new 
      @attr_packs = {}
      @meta = {}
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
      opts[:guid_attr] ||= 'id'
      opts[:max_guid]  ||= (data.last[opts[:guid_attr].to_sym] || data.last[opts[:guid_attr].to_s])

      build_pack(opts) do |p|
        data.each { |d| p << d }
      end
    end

    def build_pack(opts={}, &block)
      guid_attr = opts[:guid_attr] || 'id'
      packs = @attr_packs.values
      max_guid  = opts[:max_guid]

      raise ArgumentError, "You must specify the max_guid to start building a pack!" if max_guid.nil?

      existence_pack.initialize_pack!(max_guid)
      packs.each { |p| p.initialize_pack!(max_guid) }

      idx = 0
      packer = ->(d) {
        guid = d[guid_attr.to_sym] || d[guid_attr.to_s]
        existence_pack.encode(guid)
        packs.each { |p| p.encode(idx, d) }
        idx += 1
      }
      packer.instance_eval { alias :<< :call; alias :add :call }

      yield(packer)

      existence_pack.finalize_pack!
      packs.each { |p| p.finalize_pack! }
    end

    def to_json(opts={})
      output = {
        existence: @existence_pack.to_h,
        attributes: Hash[@attr_packs.values.map { |p| [p.attr_name, p.to_h] }]
      }

      output.merge!(meta)
      output
    end

  end
end