module Tamper
  class ExistencePack < Pack

    def initialize
      @output = ''
      @current_chunk = ''
      @last_guid = 0
    end

    def initialize_pack!(max_guid, num_items)
    end

    def encoding
      :existence
    end

    def encode(guid)
      guid_diff  = guid.to_i - @last_guid
      guid_diff += 1 if @current_chunk.empty? && @output.empty? && guid.to_i > 0

      if guid_diff == 1 || guid.to_i == 0  # guid is 1 step forward
        @current_chunk << '1'
      
      elsif guid_diff <= 0  # somehow we went backwards or didn't change guid on iteration
        raise ArgumentError, "Error: data was not sorted by GUID (got #{@last_guid}, then #{guid})!"
    
      elsif guid_diff > 40  # big gap, encode with skip control char
        write_keep(@current_chunk)

        @output += control_code(:skip, guid_diff - 1)
        @current_chunk = '1'
    
      else # skips < 40 should just be encoded as '0'
        if @current_chunk.length > 40   # first check if a run came before this 0; if so dump it
          write_keep(@current_chunk)
          @current_chunk = ''
        end
        @current_chunk += ('0' * (guid_diff - 1))
        @current_chunk << '1'
      end

      @last_guid = guid.to_i
    end

    def finalize_pack!
      write_keep(@current_chunk)
      raise "Encoding error, #{@output.length} is not an even number of bytes!" if @output.length % 8 > 0
      @bitset = Bitset.from_s(@output)
    end

    def to_h
      { encoding: encoding,
        pack: encoded_bitset }
    end


    private
    def write_keep(chunk)
      if chunk.length > 40
        @output += control_code(:run, chunk.length)
      elsif !chunk.empty?
        @output += control_code(:keep, chunk.length)
        @output += chunk

        # If the keep is not an even number of bytes, pad with 0 until it can be evenly packed
        if (@output.length % 8) > 0
          @output += '0' * (8 - (@output.length % 8))
        end
      end
    end

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
      when :run
        control_seq = '00000010'
        control_seq += offset.to_s(2).rjust(32)
      else
        raise "Unknown control cmd '#{cmd}'!"
      end
      control_seq
    end

  end
end
