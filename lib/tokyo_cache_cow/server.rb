require 'strscan'

class TokyoCacheCow
  class Server < EventMachine::Connection
    
    Terminator = "\r\n"
    
    #set
    SetCommand = /(set|add|replace|append|prepend) (.*) (\d+) (\d+) (\d+)( noreply)?/
    CasCommand = /cas (.*) (\d+) (\d+) (\d+) (\d+)( noreply)?/
    
    StoredReply = "STORED\r\n"
    NotStoredReply = "NOT_STORED\r\n"
    ExistsReply = "EXISTS\r\n"
    NotFoundReply = "NOT_FOUND\r\n"
    
    #get
    GetCommand = /(gets?) (.*)/
    
    EndReply = "END\r\n"
    
    GetValueReply = "VALUE %s %d %d\r\n"
    CasValueReply = "VALUE %d %d %d %d\r\n"
    
    #delete
    DeleteCommand = /delete (.*)( noreply)?/
    DeleteWithTimeoutCommand = /delete (.*) (\d*)( noreply)?/
    
    DeletedReply = "DELETED\r\n"
    NotDeletedReply = "NOT_DELETED\r\n"
    
    #delete_match
    DeleteMatchCommand = /delete_match (.*)( noreply)?/

    #Increment/Decrement
    IncrementDecrementCommand = /(incr|decr) (.*) (\d+)( noreply)?/
    
    ValueReply = "%d\r\n"
    
    #stats
    
    StatsCommand = /stats/
    
    #others
    FlushAllCommand = /flush_all/
    VersionCommand = /version/
    QuitCommand = /version/
    
    #errors
    Error = "ERROR\r\n" 
    ClientError = "CLIENT_ERROR %s\r\n"
    ServerError = "SERVER_ERROR %s\r\n"
    
    attr_accessor :cache
    
    def receive_data(data)
      send_data(Error) and return unless data.index("\r\n")
      
      ss = StringScanner.new(data)
      command = ss.scan_until(/\r\n/)
      command.chomp!
      case command
      when SetCommand
        (cmd, key, flags, exptime, bytes, noreply) = [$1, $2, $3, $4, $5, !$6.nil?]
        exptime = case exptime.to_i
        when 0: '0'
        when 1..Time.now.to_i : (Time.now.to_i + exptime.to_i).to_s
        else exptime
        end
        
        # (set|add|replace|append|prepend)
        case cmd
        when 'set'
          send_data(@cache.put(key, {'flags' => flags, 'exptime' => exptime, 'data' => ss.rest[0, bytes.to_i]}) ?
            StoredReply : NotStoredReply)
        when 'add'
          send_data(@cache.putkeep(key, {'flags' => flags, 'exptime' => exptime, 'data' => ss.rest[0, bytes.to_i]}) ?
            StoredReply : NotStoredReply)
        when 'replace'
          send_data(@cache.putover(key, {'flags' => flags, 'exptime' => exptime, 'data' => ss.rest[0, bytes.to_i]}) ?
            StoredReply : NotStoredReply)
        when 'append'
          send_data(@cache.append(key, ss.rest[0, bytes.to_i]) ?
            StoredReply : NotStoredReply)
        when 'prepend'
          send_data(@cache.prepend(key, ss.rest[0, bytes.to_i]) ?
            StoredReply : NotStoredReply)
        end
      when CasCommand
      when GetCommand
        (cmd, keys) = [$1, $2.split(/\s+/)]
        keys.each do |k|
          if data = @cache.get(k)
            send_data(GetValueReply % [k, data['flags'], data['data'].size])
            send_data(data['data'])
            send_data(Terminator)
          end
        end
        send_data(EndReply)
      when DeleteWithTimeoutCommand
        send_data(Error)
      when DeleteCommand
        (key, timeout) = [$1, $2]
        send_data @cache.delete(key) ?
          DeletedReply : NotDeletedReply
      when DeleteMatchCommand
        key = $1
        @cache.delete_match(key)
        send_data(DeletedReply)
      when IncrementDecrementCommand
        (cmd, key, value, noreply) = [$1, $2, $3.to_i, !$4.nil?]
        send_data(if d = @cache.get(key)
          value = -value if cmd == 'decr'
          d['data'] = (val = (d['data'].to_i + value)).to_s
          @cache.put(key, d)
          ValueReply % val
        else
          NotFoundReply
        end)
      when StatsCommand
        send_data(Error)
      when FlushAllCommand
        send_data(Error)
      when VersionCommand
        send_data(Error)
      when QuitCommand
        send_data(Error)
      else
        send_data(Error)
      end
    end
    
  end
end