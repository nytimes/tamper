module Tamper
  class ExistencePack < Pack

    def initialize
      @output = ''
      @current_chunk = ''
      @last_guid = 0
    end

    def initialize_pack!(max_guid)
    end

    def encoding
      :existence
    end

    def encode(idx, data)
      guid_diff = idx.to_i - @last_guid

      if guid_diff == 1 || idx.to_i == 0  # guid exists
        @current_chunk << '1'
      
      elsif guid_diff <= 0  # somehow we went backwards or didn't change guid on iteration
        raise ArgumentError, "Error: data was not sorted by GUID (got #{@last_guid}, then #{idx})!"
    
      elsif guid_diff > 20  # big gap, encode with skip control char
        @output += control_code(:keep, @current_chunk.length) unless @current_chunk.empty?
        @output += @current_chunk
        @output += control_code(:skip, (guid_diff - 1))
        @current_chunk = '1'
    
      else # skips < 20 should just be encoded as '0'
        @current_chunk += ('0' * (guid_diff - 1))
        @current_chunk << '1'
      end

      @last_guid = idx.to_i
    end

    def finalize_pack!
      @output += control_code(:keep, @current_chunk.length)  # need to keep final chunk
      @output += @current_chunk

      @bitset = Bitset.from_s(@output)
    end

    def to_h
      { encoding: encoding,
        pack: encoded_bitset }
    end


    private
    def control_code(cmd, offset=0)
      case cmd
      when :keep
        control_seq = '00'
      when :skip
        control_seq = '01'
      else
        raise "Unknown control cmd '#{cmd}'!"
      end

      control_seq += offset.to_s(2).rjust(16)

      control_seq
    end

  end
end