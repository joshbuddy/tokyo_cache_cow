$:.unshift(File.dirname(__FILE__))

class TokyoCacheCow
  class Cache
    self.autoload :Base, 'cache/base'
    self.autoload :FileMemcache, 'cache/file_memcache'
    self.autoload :TokyoCabinetMemcache, 'cache/tokyo_cabinet_memcache'
    self.autoload :HashMemcache, 'cache/hash_memcache'
  end
end

