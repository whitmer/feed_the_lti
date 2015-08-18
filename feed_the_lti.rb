require 'sinatra/base'
require 'oauth'
require 'json'
require 'dm-core'
require 'dm-migrations'
require 'nokogiri'
require 'oauth/request_proxy/rack_request'
require 'ims/lti'
require 'feedjira'

require './lib/api.rb'
require './lib/auth.rb'
require './lib/feed_handler.rb'
require './lib/models.rb'
require './lib/views.rb'

class FeedTheMe < Sinatra::Base
  register Sinatra::Api
  register Sinatra::Auth
  register Sinatra::Views
  
  # sinatra wants to set x-frame-options by default, disable it
  disable :protection
  # enable sessions so we can remember the launch info between http requests, as
  # the user takes the assessment
  enable :sessions

  # set session key in heroku with: heroku config:add SESSION_KEY=a_longish_secret_key
  raise "session key required" if ENV['RACK_ENV'] == 'production' && !ENV['SESSION_KEY']
  set :session_secret, ENV['SESSION_KEY'] || "local_secret"

  set :method_override, true

  Feedjira::Feed.add_common_feed_element(:link, :as => :hub, :value => :href, :with => {:rel => "hub"})

  env = ENV['RACK_ENV'] || settings.environment
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || ENV["HEROKU_POSTGRESQL_BRONZE_URL"] || "sqlite3:///#{Dir.pwd}/#{env}.sqlite3"))
  DataMapper.auto_upgrade!
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
