class TokyoCacheCow
  class Cache
    class HashMemcache < Base
      
      def process_time(time)
        time = case time
        when 0, nil: 0
        when 1..2592000: (Time.now.to_i + time.to_i)
        else time
        end
      end

      def initialize(options = {})
        @cache = {}
      end
      
      def time_expired?(time)
        time.to_i == 0 ? false : time < Time.now.to_i
      end

      def generate_data_hash(value, options)
        {
          :value => marshal(value),
          :expires => process_time(options[:expires] || 0),
          :flags => options[:flags] || 0
        }
      end
      
      def add(key, value, options = {})
        if (data = @cache[key]) && !time_expired?(data[:expired])
          nil
        else
          set(key, value, options) and true
        end
      end

      def delete_match(key)
        @cache.delete_if{ |key, value| key.index(key) }
      end

      def get_match(match)
        @cache.keys.select{ |key| key.index(key) }
      end

      def replace(key, value, options = {})
        set(key, value, options) if @cache.key?(key)
      end

      def append(key, val)
        if data = get(key)
          data[:value] << val
          @cache[key] = data
          true
        else
          false
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
      
      def flush_all
        @cache.clear and true
      end

      def delete(key, expires = nil)
        @cache.delete(key)
      end
      
      def get(key)
        if data = @cache[key]
          if time_expired?(data[:expires])
            @cache.delete(key)
            nil
          else
            data
          end
        end
      end

      def set(key, value, options = {})
        @cache[key] = generate_data_hash(value, options)
      end

    end
  end
end
