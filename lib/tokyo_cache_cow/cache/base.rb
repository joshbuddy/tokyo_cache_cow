class TokyoCacheCow
  class Cache
    class Base
      
      attr_accessor :marshalling_enabled
      
      def marshal(val)
        marshalling_enabled ? Marshal.dump(val) : val
      end
      
      def unmarshal(val)
        marshalling_enabled ? Marshal.load(val) : val
      end
      
      def process_time(time)
        time = case time
        when 0, nil: 0
        when 1..2592000: (Time.now.to_i + time.to_i)
        else time
        end
      end

      def avg_match(match)
        values = numeric_values_match(match)
        marshal(values.inject(0.0) { |sum, el| sum + el } / values.size)
      end
      
      def sum_match(match)
        values = numeric_values_match(match)
        marshal(values.inject(0.0) { |sum, el| sum + el })
      end
      
      def count_match(match)
        values = numeric_values_match(match)
        marshal(values.size)
      end
      
      def min_match(match)
        values = numeric_values_match(match)
        marshal(values.min)
      end
      
      def max_match(match)
        values = numeric_values_match(match)
        marshal(values.max)
      end
      
      def numeric_values_match(match)
        numeric_keys = get_match(match)
        numeric_keys.map{|ak| get(ak)}.map{|v| Integer(unmarshal(v[:value])) rescue nil}.compact
      end
      
      def get_match_list(match)
        marshal(get_match(match).join(' '))
      end
      
    end
  end
end