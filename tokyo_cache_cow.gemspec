# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tokyo_cache_cow}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Hull"]
  s.date = %q{2009-05-14}
  s.default_executable = %q{tokyo_cache_cow}
  s.description = %q{}
  s.email = %q{joshbuddy@gmail.com}
  s.executables = ["tokyo_cache_cow"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["Rakefile", "README.rdoc", "VERSION.yml", "lib/tokyo_cache_cow", "lib/tokyo_cache_cow/cache", "lib/tokyo_cache_cow/cache/base.rb", "lib/tokyo_cache_cow/cache/file_memcache.rb", "lib/tokyo_cache_cow/cache/hash_memcache.rb", "lib/tokyo_cache_cow/cache/tokyo_cabinet_memcache.rb", "lib/tokyo_cache_cow/cache.rb", "lib/tokyo_cache_cow/providers.rb", "lib/tokyo_cache_cow/runner.rb", "lib/tokyo_cache_cow/server.rb", "lib/tokyo_cache_cow.rb", "spec/cache_spec.rb", "spec/server_spec.rb", "spec/spec.opts", "rails/init.rb", "bin/tokyo_cache_cow"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/joshbuddy/tokyo_cache_cow}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
