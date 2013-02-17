begin
  require 'rubygems'
rescue LoadError
  puts "You must install rubygems to run this example"
  raise
end

begin
  require 'bundler/setup'
rescue LoadError
  puts "to set up this example, run these commands:"
  puts "  gem install bundler"
  puts "  bundle install"
  raise
end

require 'sinatra'
require 'oauth'
require 'json'
require 'dm-core'
require 'dm-migrations'
require 'nokogiri'
require 'oauth/request_proxy/rack_request'
require 'ims/lti'

require './lib/api.rb'
require './lib/auth.rb'
require './lib/feed_handler.rb'
require './lib/models.rb'
require './lib/views.rb'

# sinatra wants to set x-frame-options by default, disable it
disable :protection
# enable sessions so we can remember the launch info between http requests, as
# the user takes the assessment
enable :sessions

def protocol
  ENV['RACK_ENV'] == 'production' ? "https" : "http"
end

class Object
  def try(method, *args)
    send(method, *args)
  end
end

class NilClass
  def try(*args)
    nil
  end
end