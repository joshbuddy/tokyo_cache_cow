require 'eventmachine'
require 'lib/tokyo_cache_cow'

cache = TokyoCacheCow::MemCache.new('/tmp/tcc')

EM.run do 
  EM.start_server("0.0.0.0", 11211, TokyoCacheCow::Server) do |c|
    c.cache = cache
  end
end
