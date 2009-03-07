require 'eventmachine'
require 'optparse'
require 'lib/tokyo_cache_cow'

options = {:port => '11211', :host => '0.0.0.0'}
OptionParser.new do |opts|
  opts.banner = "Usage: runner.rb [options]"

  opts.on("-p[OPTIONAL]", "--port", "Port (default: #{options[:port]})") do |v|
    options[:port] = v
  end

  opts.on("-h[OPTIONAL]", "--host", "Host (default: #{options[:host]})") do |v|
    options[:host] = v
  end

  opts.on_tail("-h", "--help", "Show this help message.") { puts opts; exit }

end.parse!

trap("INT") { EM.stop; puts "moooooooo ya later" }

cache = TokyoCacheCow::MemCache.new('/tmp/tcc')

puts "Starting the tokyo cache cow"
EM.run do 
  EM.start_server(options[:host], options[:port], TokyoCacheCow::Server) do |c|
    c.cache = cache
  end
end

