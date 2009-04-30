require 'rubygems'
require 'memcached'
require 'benchmark'
require 'lib/tokyo_cache_cow'

cache = Memcached.new('127.0.0.1:11211')

describe 'memcache server' do
  
  before(:all) do
    runner = TokyoCacheCow::Runner.new(['--daemonize'])
    @pid = runner.start!
    sleep(1)
  end
  
  before(:each) do 
    cache.flush
  end
  
  it "should get & set" do
    cache.set('asd', "qweqweasd")
    cache.get('asd').should == "qweqweasd"
  end
  
  it "should delete" do
    cache.set('asd', 'qwe')
    cache.delete('asd')
    proc {cache.get('asd')}.should raise_error Memcached::NotFound
  end

  after(:all) do
    Process.kill('INT', @pid)
  end
  
  
end
