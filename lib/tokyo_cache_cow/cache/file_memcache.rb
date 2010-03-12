require 'yaml'
require 'fileutils'
require 'cgi'

class TokyoCacheCow
  class Cache
    class FileMemcache < Base
      
      def process_time(time)
        time = case time
        when 0, nil: 0
        when 1..2592000: (Time.now.to_i + time.to_i)
        else time
        end
      end

      def initialize(options = {})
        @path = options[:file] or raise('must supply file')
        flush_all
      end
      
      def time_expired?(time)
        time.to_i == 0 ? false : time < Time.now.to_i
      end

      def generate_data_hash(value, options)
        {
          :value => value,
          :expires => process_time(options[:expires] || 0),
          :flags => options[:flags] || 0
        }
      end
      
      def add(key, value, options = {})
        if (data = get_raw(key)) && !time_expired?(data[:expired])
          nil
        else
          set(key, value, options) and true
        end
      end

      def delete_match(key)
        FileUtils.rm Dir.glob(File.join(@path, "*#{CGI.escape(key)}*"))
      end

      def get_match(key)
        Dir.glob(File.join(@path, "*#{CGI.escape(key)}*")).map{|d| d}.map{|f| File.basename(f)}
      end

      def replace(key, value, options = {})
        set(key, value, options) if File.exists?(path_for_key(key))
      end

      def append(key, val)
        if data = get(key)
          data[:value] << val
          set_raw(key, data)
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
        FileUtils.rm_rf(@path)
        FileUtils.mkdir_p(@path)
        true
      end

      def delete(key, expires = nil)
        FileUtils.rm(Dir.glob(path_for_key(key))) and true
      end
      
      def path_for_key(key)
        File.join(@path, CGI.escape(key))
      end
      
      def get_raw(key)
        File.exists?(path_for_key(key)) ? YAML::load( File.open( path_for_key(key) ) ) : nil
      end
      
      def set_raw(key, data)
        File.open(path_for_key(key), 'w') do |out|
          YAML.dump(data, out)
        end
      end
      
      def get(key)
        if data = get_raw(key)
          if time_expired?(data[:expires])
            delete(key)
            nil
          else
            data
          end
        end
      end

      def set(key, value, options = {})
        set_raw(key, generate_data_hash(value, options))
      end

    end
  end
end
