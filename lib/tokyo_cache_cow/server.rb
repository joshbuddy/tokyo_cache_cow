require 'strscan'
require 'eventmachine'

class TokyoCacheCow
  class Server < EventMachine::Protocols::LineAndTextProtocol
    
    DefaultPort = 11211
    
    Terminator = "\r\n"
    
    #set
    SetCommand = /(\S+) +(\d+) +(\d+) +(\d+)( +noreply)?/
    CasCommand = /(\S+) +(\d+) +(\d+) +(\d+) +(\d+)( +noreply)?/
    
    StoredReply = "STORED\r\n"
    NotStoredReply = "NOT_STORED\r\n"
    ExistsReply = "EXISTS\r\n"
    NotFoundReply = "NOT_FOUND\r\n"
    
    GetValueReply = "VALUE %s %d %d\r\n"
    CasValueReply = "VALUE %d %d %d %d\r\n"
    EndReply = "END\r\n"
    
    #delete
    DeleteCommand = /(\S+) *(noreply)?/
    DeleteWithTimeoutCommand = /(\S+) +(\d+) *(noreply)?/
    
    DeletedReply = "DELETED\r\n"
    NotDeletedReply = "NOT_DELETED\r\n"
    
    #delete_match
    DeleteMatchCommand = /(\S+)( +noreply)?/

    #Increment/Decrement
    IncrementDecrementCommand = /(\S+) +(\d+)( +noreply)?/
    
    ValueReply = "%d\r\n"
    
    #errors
    OK = "OK\r\n" 
    Error = "ERROR\r\n" 
    ClientError = "CLIENT_ERROR %s\r\n"
    ServerError = "SERVER_ERROR %s\r\n"
    
    TerminatorRegex = /\r\n/
    
    attr_accessor :cache, :special_match_char
    
    def send_client_error(message = "invalid arguments")
      send_data(ClientError % message.to_s)
    end
    
    def send_server_error(message = "there was a problem")
      send_data(ServerError % message.to_s)
    end
    
    def validate_key(key)
      if key.nil?
        send_data(ClientError % "key cannot be blank")
      elsif key && key.index(' ')
        send_data(ClientError % "key cannot contain spaces")
        nil
      elsif key.size > 250
        send_data(ClientError % "key must be less than 250 characters")
        nil
      else
        key
      end
    end
    
    def set_incomplete(ss, length, part)
      if ss.rest.size < length
        @expected_size = length + ss.pre_match.size + 2
        if @body
          @body << ss.string
        else
          @body = part
          @body << ss.rest
        end
        true
      else
        false
      end
    end
    
    def receive_data(data)
      if @body
        @body << data
        return if @body.size < @expected_size
      end
      
      ss = StringScanner.new(@body || data)
      
      while part = ss.scan_until(TerminatorRegex)
        begin
          command_argument_separator_index = part.index(/\s/)
          command = part[0, command_argument_separator_index]
          args = part[command_argument_separator_index + 1, part.size - command_argument_separator_index - 3]
          case command
          when 'get', 'gets'
            keys = args.split(/\s+/)
            keys.each do |k|
              next unless validate_key(k)
              if special_match_char && k.index(special_match_char) == 0
                k.slice!(0, special_match_char.size)
                value = @cache.get_match_list(k)
                send_data(GetValueReply % [k, "0", value.size])
                send_data(value)
                send_data(Terminator)
              elsif k =~ /^(avg|sum|count|min|max)\((.*?)\)$/
                value = @cache.send(:"#{$1}_match", $2).to_s
                send_data(GetValueReply % [k, "0", value.size])
                send_data(value)
                send_data(Terminator)
              else
                if data = @cache.get(k)
                  if command == 'get'
                    send_data(GetValueReply % [k, data[:flags], data[:value].size])
                  else
                    send_data(CasValueReply % [k, data[:flags], data[:value].size, data[:value].hash])
                  end
                  send_data(data[:value])
                  send_data(Terminator)
                end
              end
              
            end
            send_data(EndReply)
          when 'set'
            SetCommand.match(args) or (send_client_error and next)
            (key, flags, expires, bytes, noreply) = [$1, Integer($2), Integer($3), Integer($4), !$5.nil?]
            next unless validate_key(key)
            return if set_incomplete(ss, bytes, part)
            send_data(@cache.set(key, ss.rest[0, bytes.to_i], :flags => flags, :expires => expires) ?
              StoredReply : NotStoredReply)
            @body = nil
            ss.pos += bytes + 2 
          when 'add'
            SetCommand.match(args)
            (key, flags, expires, bytes, noreply) = [$1, $2.to_i, $3.to_i, $4, !$5.nil?]
            return if set_incomplete(ss, bytes, part)
            send_data(@cache.add(key, ss.rest[0, bytes.to_i], :flags => flags, :expires => expires) ?
              StoredReply : NotStoredReply)
            @body = nil
            ss.pos += bytes + 2 
          when 'replace'
            SetCommand.match(args)
            (key, flags, expires, bytes, noreply) = [$1, $2.to_i, $3.to_i, $4, !$5.nil?]
            return if set_incomplete(ss, bytes, part)
            send_data(@cache.replace(key, ss.rest[0, bytes.to_i], :flags => flags, :expires => expires) ?
              StoredReply : NotStoredReply)
            @body = nil
            ss.pos += bytes + 2 
          when 'append'
            SetCommand.match(args)
            (key, flags, expires, bytes, noreply) = [$1, $2.to_i, $3.to_i, $4, !$5.nil?]
            return if set_incomplete(ss, bytes, part)
            send_data(@cache.append(key, ss.rest[0, bytes.to_i], :flags => flags, :expires => expires) ?
              StoredReply : NotStoredReply)
            @body = nil
            ss.pos += bytes + 2 
          when 'prepend'
            SetCommand.match(args)
            (key, flags, expires, bytes, noreply) = [$1, $2.to_i, $3.to_i, $4, !$5.nil?]
            return if set_incomplete(ss, bytes, part)
            send_data(@cache.prepend(key, ss.rest[0, bytes.to_i], :flags => flags, :expires => expires) ?
              StoredReply : NotStoredReply)
            @body = nil
            ss.pos += bytes + 2 
          when 'cas'
            # do something
          when 'delete'
            split_args = args.split(/\s+/)
            (key, timeout, noreply) = case split_args.size
            when 2
              [split_args[0].chomp, 0, !split_args[1].nil?]
            when 3
              [split_args[0].chomp, split_args[1].to_i, !split_args[2].nil?]
            else
              (send_client_error and next)
            end
            next unless validate_key(key)
            if special_match_char && key.index(special_match_char) == 0
              key.slice!(0,special_match_char.size)
              @cache.delete_match(key)
              send_data(DeletedReply)
            else
              send_data @cache.delete(key, :expires => timeout) ?
                DeletedReply : NotDeletedReply
            end
          when 'delete_match'
            DeleteMatchCommand.match(args)
            (key, noreply) = [$1.chomp, !$2.nil?]
            next unless validate_key(key)
            @cache.delete_match(key)
            send_data(DeletedReply)
          when 'incr', 'decr'
            IncrementDecrementCommand.match(args)
            (key, value, noreply) = [$1, $2.to_i, !$3.nil?]
            next unless validate_key(key)
            send_data(if d = @cache.get(key)
              value = -value if command == 'decr'
              d['data'] = (val = (d['data'].to_i + value)).to_s
              @cache.put(key, d)
              ValueReply % val
            else
              NotFoundReply
            end)
          when 'stats'
            send_data(Error)
          when 'flush_all'
            send_data(@cache.flush_all ? OK : Error)
          when 'version'
            send_data(Error)
          when 'quit'
            close_connection_after_writing
          else
            send_data(Error)
          end
        rescue
          puts $!
          puts $!.backtrace
          send_server_error($!)
        end
      end
      
    end
    
  end
end