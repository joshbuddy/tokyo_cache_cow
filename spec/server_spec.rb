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
    cache.set('asd', "qweqweasd" * 20000)
    cache.get('asd').should == "qweqweasd" * 20000
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

describe 'memcache server with special delete support' do
  
  before(:all) do
    runner = TokyoCacheCow::Runner.new(['--daemonize', '-m...'])
    @pid = runner.start!
    sleep(1)
  end
  
  before(:each) do 
    cache.flush
  end
  
  it "should delete match through special char " do
    cache.set('asd123', "qweqweasd")
    cache.set('asd456', "qweqweasd")
    cache.set('asd678', "qweqweasd")
    cache.set('qwe678', "qweqweasd")
    cache.set('qwe679', "qweqweasd")
    cache.delete('...asd')
    proc {cache.get('asd123')}.should raise_error Memcached::NotFound
    proc {cache.get('asd456')}.should raise_error Memcached::NotFound
    proc {cache.get('asd678')}.should raise_error Memcached::NotFound
    cache.delete('...qwe678')
    proc {cache.get('qwe678')}.should raise_error Memcached::NotFound
    cache.get('qwe679').should=='qweqweasd'
  end
  
  after(:all) do
    Process.kill('INT', @pid)
  end
  
  
end
