class TokyoCacheCow
  
  autoload :TokyoCabinetMemcache, 'lib/tokyo_cache_cow/tokyo_cabinet_memcache'

  class Providers
    
    def self.provide_cache
      #require 'lib/tokyo_cache_cow/tokyo_cabinet_memcache'
      @@cache ||= TokyoCacheCow::TokyoCabinetMemcache.new('/tmp/tcc')
    end
    
  end
end