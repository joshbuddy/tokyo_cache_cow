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
        values = numeric_values_match(match)
        values.inject(0.0) { |sum, el| sum + el } / values.size
      end
      
      def sum_match(match)
        values = numeric_values_match(match)
        values.inject(0.0) { |sum, el| sum + el }
      end
      
      def count_match(match)
        values = numeric_values_match(match)
        values.size
      end
      
      def min_match(match)
        values = numeric_values_match(match)
        values.min
      end
      
      def max_match(match)
        values = numeric_values_match(match)
        values.max
      end
      
      def numeric_values_match(match)
        numeric_keys = get_match(match)
        numeric_keys.map{|ak| get(ak)}.map{|v| Integer(v[:value]) rescue nil}.compact
      end
      
    end
  end
end