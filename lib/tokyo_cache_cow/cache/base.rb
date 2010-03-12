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
      
      def average_match(match)
        average_keys = get_match(match)
        values = average_keys.map{|ak| get(ak)}.map{|v| Integer(v[:value]) rescue nil}.compact
        values.inject(0.0) { |sum, el| sum + el } / values.size
      end
      
    end
  end
end