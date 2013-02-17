require 'sinatra/base'

module Sinatra
  module Api
    # get feed entries for the specified course, possibly filtered to a specific feed id
    get "/api/v1/courses/:course_id/entries.json" do
      return {:error => "not authorized"}.to_json unless participant?(params['course_id'])
      course = Context.first(:context_type => 'course', :id => params['course_id'])
      params['feed_id'] ||= 'all'
      page = params['page'].to_i
      entries = course.results_for(page, params['feed_id'])
      if entries.delete(:next)
        entries[:meta] = {:next => "/api/v1/courses/#{course.id}/entries.json?page=#{page + 1}&feed_id=#{params['feed_id']}"}
      end
      if page > 0
        entries[:meta] ||= {}
        entries[:meta][:previous] = "/api/v1/courses/#{course.id}/entries.json?page=#{page - 1}&feed_id=#{params['feed_id']}"
      end
      entries.to_json
    end
    
    # pubsubhubbub init check
    get "/api/v1/feeds/:feed_id/:nonce.json" do
      feed = Feed.first(:id => params['feed_id'], :nonce => params['nonce'])
      if params['hub.mode'] == 'unsubscribe'
        feed.disable if feed
      end
      if feed && ['subscribe', 'unsubscribe'].include?(params['hub.mode'])
        return params['hub.challenge'] || "no challenge provided"
      else
        return "not found"
      end
    end
    
    # pubsubhubbub callback
    post "/api/v1/feeds/:feed_id/:nonce.json" do
      # TODO: return X-Hub-On-Behalf-Of (approximate # of users)
      feed = Feed.first(:id => params['feed_id'], :nonce => params['nonce'])
      # TODO: rate limit feed checks
      new_entries = feed.check_for_entries if feed
      {:found => !!feed, :new_entries => (new_entries || 0), :feed => (feed && feed.as_json)}.to_json
    end
    
    # get feed entries for the specified user, possibly filtered to a specific feed id
    get "/api/v1/users/:user_id/entries.json" do
      params['user_id'] = session['user_id'] if params['user_id'] == 'self'
      return error("Session required") unless session['user_id']
      return error("Not authorized") unless session['user_id'] == params['user_id']
    end
    
    post "/api/v1/courses/:course_id/feeds.json" do
      course = Context.first(:context_type => 'course', :id => params['course_id'])
      user = Context.first(:context_type => 'user', :id => session['user_id']) if session['user_id']
      return {:error => "not authorized"}.to_json unless admin?(params['course_id']) || (course && course.allow_student_feeds)
      return {:error => "not found"}.to_json unless course
      feed = course.create_feed(params['url'], params['filter'], session['user_id'], "#{protocol}://#{request.host_with_port}")
      # tie the feed to the user as well
      user.create_feed(params['url'], params['filter'], session['user_id'], "#{protocol}://#{request.host_with_port}") if user
      feed.to_json
    end
    
    get "/api/v1/courses/:course_id/feeds.json" do
      course = Context.first(:context_type => 'course', :id => params['course_id'])
      return {:error => "not authorized"}.to_json unless admin?(params['course_id']) || (course && course.allow_student_feeds)
      return {:error => "not found"}.to_json unless course
      page = params['page'].to_i
      feeds = course.feeds.all(:limit => 26, :offset => (page * 25))
      res = {
        :objects => feeds[0, 25].map(&:as_json)
      }
      if feeds.length > 25
        res[:meta] = {:next => "/api/v1/courses/#{params['course_id']}/feeds.json?page=#{page + 1}"}
      end
      if page > 0
        res[:meta] ||= {}
        res[:meta][:previous] = "/api/v1/courses/#{params['course_id']}/feeds.json?page=#{page - 1}"
      end
      res.to_json
    end
    
    get "/api/v1/users/:user_id/feeds.json" do
      params['user_id'] = session['user_id'] if params['user_id'] == 'self'
      return error("Session required") unless session['user_id']
      return error("Not authorized") unless session['user_id'] == params['user_id']
    end
    
    # get data on a specific feed
    get "/api/v1/feeds/:id.json" do
    end
    
    # create a new feed
    post "/api/v1/feeds.json" do
      # check if it already exists first. if so, just tie to existing feed
      # include filter at the context level
    end
    
    helpers do 
    end
  end
  
  register Api
end
