class TokyoCacheCow
  class Cache
    class Base
      
      def process_time(time)
        time = case time
        when 0, nil: 0
        when 1..2592000: (Time.now.to_i + time.to_i)
        else time
        end
      end
      
    end
  end
end