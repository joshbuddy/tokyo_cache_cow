# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tokyo_cache_cow}
  s.version = "0.0.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Hull"]
  s.date = %q{2010-04-22}
  s.default_executable = %q{tokyo_cache_cow}
  s.description = %q{}
  s.email = %q{joshbuddy@gmail.com}
  s.executables = ["tokyo_cache_cow"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "bin/tokyo_cache_cow",
    "lib/tokyo_cache_cow.rb",
    "lib/tokyo_cache_cow/cache.rb",
    "lib/tokyo_cache_cow/cache/base.rb",
    "lib/tokyo_cache_cow/cache/file_memcache.rb",
    "lib/tokyo_cache_cow/cache/hash_memcache.rb",
    "lib/tokyo_cache_cow/cache/tokyo_cabinet_memcache.rb",
    "lib/tokyo_cache_cow/runner.rb",
    "lib/tokyo_cache_cow/server.rb",
    "rails/init.rb",
    "spec/cache_spec.rb",
    "spec/server_spec.rb",
    "spec/spec.opts"
  ]
  s.homepage = %q{http://github.com/joshbuddy/tokyo_cache_cow}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{}
  s.test_files = [
    "spec/cache_spec.rb",
    "spec/server_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
  end
end

