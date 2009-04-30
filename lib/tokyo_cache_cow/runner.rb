require 'eventmachine'
require 'optparse'

class TokyoCacheCow
  class Runner

    attr_reader :options
    
    def initialize(argv)
      @argv = argv
      
      # Default options values
      @options = {
        :chdir                => Dir.pwd,
        :address              => '0.0.0.0',
        :port                 => Server::DefaultPort,
        :class                => 'TokyoCacheCow::Cache::TokyoCabinetMemcache',
        :require              => [],
        :file                 => '/tmp/tcc-cache'
      }
      
      parse!
    end

    def parser
      OptionParser.new do |opts|
        opts.banner = "Usage: tokyo_cache_cow [options]"

        opts.separator ""
        opts.separator "Options:"

        opts.on("-p[OPTIONAL]", "--port", "Port (default: #{options[:port]})") do |v|
          options[:port] = v
        end

        opts.on("-a[OPTIONAL]", "--address", "Address (default: #{options[:address]})") do |v|
          options[:address] = v
        end

        opts.on("-c[OPTIONAL]", "--class", "Cache provider class (default: #{options[:class]}") do |v|
          options[:provider] = v
        end

        opts.on("-r[OPTIONAL]", "--require", "require") do |v|
          options[:require] << v
        end

        opts.on("-f[OPTIONAL]", "--file", "File (default: #{options[:file]})") do |v|
          options[:file] = v
        end

        opts.on_tail("-h", "--help", "Show this help message.") { puts opts; exit }

      end
    end

    def parse!
      parser.parse!(@argv)
    end
    
    def start!
      trap("INT") { EM.stop; puts "\nmoooooooo ya later" }
      
      options[:require].each {|r| require r}
      
      clazz = options[:class].to_s.split('::').inject(Kernel) do |parent, mod|
        parent.const_get(mod)
      end
      
      cache = clazz.new(:file => options[:file])

      puts "Starting the tokyo cache cow #{options[:address]} #{options[:port]}"
      EM.run do 
        EM.start_server(options[:address], options[:port], TokyoCacheCow::Server) do |c|
          c.cache = cache
        end
      end
      
    end
    
  end
end
