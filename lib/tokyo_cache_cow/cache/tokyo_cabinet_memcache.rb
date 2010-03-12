require 'tokyocabinet'

class TokyoCacheCow
  class Cache
    class TokyoCabinetMemcache < Base

      include TokyoCabinet

      def process_time(time)
        time = case time_i = Integer(time)
        when 0: '0'
        when 1..2592000: (Time.now.to_i + time_i).to_s
        else time
        end
      end
    
      def flush_all
        @cache.vanish
      end

      def get(key, cas = nil)
        if (data = @cache.get(key)) && data['expired']
          nil
        elsif data
          expires = data['expires'] && data['expires'].to_i
          flags = data['flags'] && data['flags'].to_i
          if expires != 0 && expires < Time.now.to_i
            delete(key)
            nil
          else
            { :value => data['value'], :expires => expires, :flags => flags }
          end
        end 
      end
    
      def incr(key, value)
        if data = get(key)
          new_value = data[:value].to_i + value
          set(key, new_value.to_s, :expires => data[:expires], :flags => data[:flags])
          new_value
        end
      end
    
      def decr(key, value)
        incr(key, -value)
      end
    
      def append(key, val)
        if data = get(key)
          data[:value] << val
          set(key, data[:value], :expires => data[:expires], :flags => data[:flags])
          true
        else
          false
        end
      end

      def prepend(key, val)
        if data = @cache.get(key)
          data[:data][0,0] = val
          put(key, data[:value], :expires => data[:expires], :flags => data[:flags])
          true
        else
          false
        end
      end
    
      def generate_data_hash(value, options)
        expires = options[:expires] && options[:expires].to_s || '0'
        flags = options[:flags] && options[:flags].to_s || '0'
        { 'value' => value, 'expires' => process_time(expires), 'flags' => flags }
      end
    
      def time_expired?(time)
        time == '0' ? false : time.to_i < Time.now.to_i
      end
    
    
      def set(key, value, options = {})
        @cache.put(key, generate_data_hash(value, options))
      end

      def add(key, value, options = {})
        if data = @cache.get(key)
          time_expired?(data[:expired]) ?
            nil : @cache.putkeep(key, generate_data_hash(value, options))
        else
          @cache.putkeep(key, generate_data_hash(value, options))
        end
      end

      def replace(key, value, options = {})
        get(key) ? @cache.put(key, generate_data_hash(value, options)) : nil
      end

      def delete(key, opts = {})
        if opts[:expires] && opts[:expires] != 0
          @cache.put(key, {'expired' => process_time(opts[:expires])})
        else
          @cache.out(key)
        end
      end

      def delete_match(match)
        q = TDBQRY.new(@cache)
        q.addcond('', TDBQRY::QCSTRINC, match)
        q.search
        q.searchout
      end

      def get_match(match)
        q = TDBQRY.new(@cache)
        q.addcond('', TDBQRY::QCSTRINC, match)
        q.search
      end

      def initialize(options = {})
        @cache = TDB::new # hash database
        raise('must supply file') unless options[:file]
        if @cache.open(options[:file], TDB::OWRITER | TDB::OCREAT | TDB::OTRUNC)
          @cache.setxmsiz(500_000_000)
        else
          puts @cache.ecode
          puts @cache.errmsg(@cache.ecode)
          raise
        end
      end

    end
  end
end