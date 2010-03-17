require 'rubygems'
require 'lib/tokyo_cache_cow'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "tokyo_cache_cow"
    s.description = s.summary = ""
    s.email = "joshbuddy@gmail.com"
    s.homepage = "http://github.com/joshbuddy/tokyo_cache_cow"
    s.authors = ["Joshua Hull"]
    s.files = FileList["[A-Z]*", "{lib,spec,rails,bin}/**/*"]
    s.executables = ['tokyo_cache_cow']
    s.add_dependency 'eventmachine'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'spec'
require 'spec/rake/spectask'

task :spec => 'spec:all'
namespace(:spec) do
  Spec::Rake::SpecTask.new(:all) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/**/*_spec.rb']
  end

end

