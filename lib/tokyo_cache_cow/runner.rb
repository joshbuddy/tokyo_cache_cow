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
        :file                 => '/tmp/tcc-cache',
        :daemonize            => false
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

        opts.on("-c[OPTIONAL]", "--class", "Cache provider class (default: #{options[:class]})") do |v|
          options[:provider] = v
        end

        opts.on("-r[OPTIONAL]", "--require", "require") do |v|
          options[:require] << v
        end

        opts.on("-f[OPTIONAL]", "--file", "File (default: #{options[:file]})") do |v|
          options[:file] = v
        end

        opts.on("-d[OPTIONAL]", "--daemonize", "Daemonize (default: #{options[:daemonize]})") do |v|
          options[:daemonize] = true
        end

        opts.on_tail("-h", "--help", "Show this help message.") { puts opts; exit }

      end
    end

    def parse!
      parser.parse!(@argv)
    end
    
    def start!
      @options[:require].each {|r| require r}
      
      clazz = @options[:class].to_s.split('::').inject(Kernel) do |parent, mod|
        parent.const_get(mod)
      end
      
      
      address = @options[:address]
      port = @options[:port]
      puts "Starting the tokyo cache cow #{address} #{port}"
      pid = EM.fork_reactor do
        cache = clazz.new(:file => @options[:file])
        trap("INT") { EM.stop; puts "\nmoooooooo ya later"; exit(0)}
        EM.run do
          EM.start_server(address, port, TokyoCacheCow::Server) do |c|
            c.cache = cache
          end
        end
      end
      
      if @options[:daemonize]
        Process.detach(pid)
      else
        trap("INT") { }
        Process.wait(pid)
      end
      
      pid
    end
    
  end
end
