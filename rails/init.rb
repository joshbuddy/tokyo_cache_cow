module ::ActiveSupport
  module Cache
    class MemCacheStore < Store

      def delete_matched(matcher, options = nil) # :nodoc:
        super
        response = @data.delete_match(matcher)
        response == Response::DELETED
      rescue MemCache::MemCacheError => e
        logger.error("MemCacheError (#{e}): #{e.message}")
        false
      end

    end
  end
end

class ::MemCache

  def delete_match(key)
    @mutex.lock if @multithread

    raise MemCacheError, "No active servers" unless active?
    cache_key = make_cache_key key
    server = get_server_for_key cache_key

    sock = server.socket
    raise MemCacheError, "No connection to server" if sock.nil?

    begin
      sock.write "delete_match #{cache_key}\r\n"
      result = sock.gets
      raise_on_error_response! result
      result
    rescue SocketError, SystemCallError, IOError => err
      server.close
      raise MemCacheError, err.message
    end
  ensure
    @mutex.unlock if @multithread
  end

end