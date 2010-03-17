class TokyoCacheCow
  class Cache
    self.autoload :Base,                 File.join('tokyo_cache_cow', 'cache', 'base')
    self.autoload :FileMemcache,         File.join('tokyo_cache_cow', 'cache', 'file_memcache')
    self.autoload :TokyoCabinetMemcache, File.join('tokyo_cache_cow', 'cache', 'tokyo_cabinet_memcache')
    self.autoload :HashMemcache,         File.join('tokyo_cache_cow', 'cache', 'hash_memcache')
  end
end

