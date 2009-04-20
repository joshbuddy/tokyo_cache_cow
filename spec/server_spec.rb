require 'rubygems'
require 'memcached'
require 'benchmark'

cache = Memcached.new('127.0.0.1:11211')

describe 'memcache server' do
  
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
  
end
