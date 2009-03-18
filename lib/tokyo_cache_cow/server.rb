require 'strscan'

class TokyoCacheCow
  class Server < EventMachine::Connection
    
    Terminator = "\r\n"
    
    #set
    SetCommand = /(.*) (\d+) (\d+) (\d+)( noreply)?/
    CasCommand = /(.*) (\d+) (\d+) (\d+) (\d+)( noreply)?/
    
    StoredReply = "STORED\r\n"
    NotStoredReply = "NOT_STORED\r\n"
    ExistsReply = "EXISTS\r\n"
    NotFoundReply = "NOT_FOUND\r\n"
    
    EndReply = "END\r\n"
    
    GetValueReply = "VALUE %s %d %d\r\n"
    CasValueReply = "VALUE %d %d %d %d\r\n"
    
    #delete
    DeleteCommand = /(.*)( noreply)?/
    DeleteWithTimeoutCommand = /(.*) (\d*)( noreply)?/
    
    DeletedReply = "DELETED\r\n"
    NotDeletedReply = "NOT_DELETED\r\n"
    
    #delete_match
    DeleteMatchCommand = /(.*)( noreply)?/

    #Increment/Decrement
    IncrementDecrementCommand = /(.*) (\d+)( noreply)?/
    
    ValueReply = "%d\r\n"
    
    #errors
    Error = "ERROR\r\n" 
    ClientError = "CLIENT_ERROR %s\r\n"
    ServerError = "SERVER_ERROR %s\r\n"
    
    attr_accessor :cache
    
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
    
    def process_time(time)
      time = case time_i = Integer(time)
      when 0: '0'
      when 1..(60*60*24*30) : (Time.now.to_i + time_i).to_s
      else time
      end
    end
    
    def receive_data(data)
      send_data(Error) and return unless data.index("\r\n")
      
      ss = StringScanner.new(data)
      command = ss.scan_until(/ /)
      command.slice!(command.size - 1)
      case command
      when 'get', 'gets'
        keys = ss.scan_until(/\r\n/).split(/\s+/)
        
        keys.each do |k|
          return unless validate_key(k)
          if data = @cache.get(k)
            command == 'get' ?
              send_data(GetValueReply % [k, data['flags'], data['data'].size]) : 
              send_data(CasValueReply % [k, data['flags'], data['data'].size, data['data'].hash])
            send_data(data['data'])
            send_data(Terminator)
          end
        end
        send_data(EndReply)
      when 'set'
        SetCommand.match(ss.scan_until(/\r\n/))
        (key, flags, exptime, bytes, noreply) = [$1, $2, process_time($3), $4, !$5.nil?]
        return unless validate_key(key)
        send_data(@cache.put(key, {'flags' => flags, 'exptime' => exptime, 'data' => ss.rest[0, bytes.to_i]}) ?
          StoredReply : NotStoredReply)
      when 'add'
        SetCommand.match(ss.scan_until(/\r\n/))
        (key, flags, exptime, bytes, noreply) = [$1, $2, process_time($3), $4, !$5.nil?]
        send_data(@cache.put_keep(key, {'flags' => flags, 'exptime' => exptime, 'data' => ss.rest[0, bytes.to_i]}) ?
          StoredReply : NotStoredReply)
      when 'replace'
        SetCommand.match(ss.scan_until(/\r\n/))
        (key, flags, exptime, bytes, noreply) = [$1, $2, process_time($3), $4, !$5.nil?]
        send_data(@cache.put_over(key, {'flags' => flags, 'exptime' => exptime, 'data' => ss.rest[0, bytes.to_i]}) ?
          StoredReply : NotStoredReply)
      when 'append'
        SetCommand.match(ss.scan_until(/\r\n/))
        (key, flags, exptime, bytes, noreply) = [$1, $2, process_time($3), $4, !$5.nil?]
        send_data(@cache.append(key, ss.rest[0, bytes.to_i]) ?
          StoredReply : NotStoredReply)
      when 'prepend'
        SetCommand.match(ss.scan_until(/\r\n/))
        (key, flags, exptime, bytes, noreply) = [$1, $2, process_time($3), $4, !$5.nil?]
        send_data(@cache.prepend(key, ss.rest[0, bytes.to_i]) ?
          StoredReply : NotStoredReply)
      when 'cas'
        # do something
      when 'delete'
        case ss.scan_until(/\r\n/)
        when DeleteWithTimeoutCommand
          (key, timeout) = [$1.chomp, process_time($2)]
          return unless validate_key(key)
          send_data(@cache.delete_expire(key, timeout) ?
            DeletedReply : NotDeletedReply)
        when DeleteCommand
          (key, noreply) = [$1.chomp, !$2.nil?]
          return unless validate_key(key)
          send_data @cache.delete(key) ?
            DeletedReply : NotDeletedReply
        end
      when 'delete_match'
        DeleteMatchCommand.match(ss.scan_until(/\r\n/))
        (key, noreply) = [$1.chomp, !$2.nil?]
        return unless validate_key(key)
        @cache.delete_match(key)
        send_data(DeletedReply)
      when 'incr', 'decr'
        IncrementDecrementCommand.match(ss.scan_until(/\r\n/))
        (key, value, noreply) = [$1, $2.to_i, !$3.nil?]
        return unless validate_key(key)
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
        send_data(Error)
      when 'version'
        send_data(Error)
      when 'quit'
        send_data(Error)
      else
        send_data(Error)
      end
    end
    
  end
end