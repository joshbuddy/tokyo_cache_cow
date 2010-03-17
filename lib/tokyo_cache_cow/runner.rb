require 'eventmachine'
require 'optparse'

class TokyoCacheCow
  class Runner

    attr_reader :options
    
    def initialize(argv)
      @argv = argv
      # Default options values
      @options = {
        :chdir                 => Dir.pwd,
        :address               => '0.0.0.0',
        :port                  => Server::DefaultPort,
        :class                 => 'TokyoCacheCow::Cache::TokyoCabinetMemcache',
        :require               => [],
        :file                  => '/tmp/tcc-cache',
        :pid                   => '/tmp/tcc.pid',
        :special_delete_prefix => nil,
        :daemonize             => false,
        :marshalling           => false
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

        opts.on("-P[OPTIONAL]", "--pid", "Pid file (default: #{options[:pid]})") do |v|
          options[:pid] = v
        end

        opts.on("-m[OPTIONAL]", "--matcher", "Special flag for doing matched deletes (not enabled by default)") do |v|
          options[:special_delete_char] = v
        end

        opts.on("-M[=OPTIONAL]", "--marshalling", "Enable/disable marshalling of values") do |v|
          options[:marshalling] = true
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
      special_delete_char = @options[:special_delete_char]
      puts "Starting the tokyo cache cow #{address} #{port}"
      pid = EM.fork_reactor do
        cache = clazz.new(:file => @options[:file])
        cache.marshalling_enabled = 
        trap("INT") { EM.stop; puts "\nmoooooooo ya later"; exit(0)}
        EM.run do
          EM.start_server(address, port, TokyoCacheCow::Server) do |c|
            c.cache = cache
            c.special_delete_char = special_delete_char if special_delete_char
          end
        end
      end
      
      if @options[:daemonize]
        File.open(options[:pid], 'w') {|f| f << pid}
        Process.detach(pid)
      else
        trap("INT") { }
        Process.wait(pid)
      end
      
      pid
    end
    
  end
end
