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

    def encode(guid)
      guid_diff  = guid.to_i - @last_guid
      guid_diff += 1 if @current_chunk.empty? && @output.empty? && guid.to_i > 0

      if guid_diff == 1 || guid.to_i == 0  # guid exists
        @current_chunk << '1'
      
      elsif guid_diff <= 0  # somehow we went backwards or didn't change guid on iteration
        raise ArgumentError, "Error: data was not sorted by GUID (got #{@last_guid}, then #{guid})!"
    
      elsif guid_diff > 40  # big gap, encode with skip control char
        @output += control_code(:keep, @current_chunk.length) unless @current_chunk.empty?
        @output += @current_chunk

        if (@output.length % 8) > 0
          @output += '0' * (8 - (@output.length % 8))
        end

        @output += control_code(:skip, guid_diff - 1)
        @current_chunk = '1'
    
      else # skips < 20 should just be encoded as '0'
        @current_chunk += ('0' * (guid_diff - 1))
        @current_chunk << '1'
      end

      @last_guid = guid.to_i
    end

    def finalize_pack!
      @output += control_code(:keep, @current_chunk.length)  # need to keep final chunk
      @output += @current_chunk
      
      if (@output.length % 8) > 0
        @output += '8' * (8 - (@output.length % 8))
      end
      raise "Encoding error, #{@output.length} is not an even number of bytes!" if @output.length % 8 > 0
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
        control_seq = '00000000'
        bytes_to_keep = offset / 8
        control_seq += bytes_to_keep.to_s(2).rjust(32)

        remaining_bits = offset % 8
        control_seq += remaining_bits.to_s(2).rjust(8)
      when :skip
        control_seq = '00000001'
        control_seq += offset.to_s(2).rjust(32)
      else
        raise "Unknown control cmd '#{cmd}'!"
      end
      control_seq
    end

  end
end
