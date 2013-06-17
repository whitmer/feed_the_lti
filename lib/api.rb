require 'sinatra/base'

module Sinatra
  module Api
    def self.registered(app)
      app.helpers Api::Helpers
      
      # get feed entries for the specified course, possibly filtered to a specific feed id
      app.get "/api/v1/:context_type/:context_id/entries.json" do
        context_type = params['context_type'].sub(/s$/, '')
        params['context_id'] = session['user_id'] if context_type == 'user' && session['user_id'] && params['context_id'] == 'self'
        return error_json("not authorized") if context_type == 'course' && !participant?(params['context_id'])
        context = Context.first(:context_type => context_type, :id => params['context_id'])
        return error_json("not found") if !context
        params['feed_id'] ||= 'all'
        page = params['page'].to_i
        entries = context.results_for(page, params['feed_id'])
        if entries.delete(:next)
          entries[:meta] = {:next => "/api/v1/#{params['context_type']}/#{context.id}/entries.json?page=#{page + 1}&feed_id=#{params['feed_id']}"}
        end
        if page > 0
          entries[:meta] ||= {}
          entries[:meta][:previous] = "/api/v1/#{params['context_type']}/#{context.id}/entries.json?page=#{page - 1}&feed_id=#{params['feed_id']}"
        end
        entries.to_json
      end
    
      # pubsubhubbub init check
      app.get "/api/v1/feeds/:raw_feed_id/:nonce.json" do
        feed = Feed.first(:id => params['raw_feed_id'], :nonce => params['nonce'])
        if params['hub.mode'] == 'unsubscribe'
          feed.disable if feed
        end
        if feed && ['subscribe', 'unsubscribe'].include?(params['hub.mode'])
          return params['hub.challenge'] || "no challenge provided"
        else
          return "not found"
        end
      end
    
      # hacky alternative to background jobs
      app.post "/api/v1/feeds/next.json" do
        feed = Feed.first(:last_checked_at.lt => (Time.now - 3600), :order => :last_checked_at.desc)
        new_entries = feed.check_for_entries if feed
        {:found => !!feed, :new_entries => (new_entries || 0)}.to_json
      end
    
      # pubsubhubbub callback
      app.post "/api/v1/feeds/:raw_feed_id/:nonce.json" do
        # TODO: return X-Hub-On-Behalf-Of (approximate # of users)
        feed = Feed.first(:id => params['raw_feed_id'], :nonce => params['nonce'])
        # TODO: rate limit feed checks
        new_entries = feed.check_for_entries if feed
        {:found => !!feed, :new_entries => (new_entries || 0)}.to_json
      end
    
      # get feed entries for the specified user, possibly filtered to a specific feed id
      app.get "/api/v1/users/:user_id/entries.json" do
        params['user_id'] = session['user_id'] if params['user_id'] == 'self'
        return error_json("session required") unless session['user_id']
        return error_json("not authorized") unless session['user_id'] == params['user_id']
      end
    
      # add a new feed to the user
      app.post "/api/v1/users/:user_id/feeds.json" do
        user = Context.first(:context_type => 'user', :id => session['user_id']) if session['user_id']
        return error_json("not found") unless user
        feed = user.create_feed(params['url'], params['filter'], session['user_id'], "#{protocol}://#{request.host_with_port}") if user
        feed.to_json
      end

      # add a new feed to the course
      app.post "/api/v1/courses/:course_id/feeds.json" do
        course = Context.first(:context_type => 'course', :id => params['course_id'])
        user = Context.first(:context_type => 'user', :id => session['user_id']) if session['user_id']
        return error_json("not authorized") unless admin?(params['course_id']) || (course && course.allow_student_feeds)
        return error_json("not found") unless course
        feed = course.create_feed(params['url'], params['filter'], session['user_id'], "#{protocol}://#{request.host_with_port}")
        # tie the feed to the user as well
        user.create_feed(params['url'], params['filter'], session['user_id'], "#{protocol}://#{request.host_with_port}") if user
        feed.to_json
      end
    
      # update course settings
      app.put "/api/v1/courses/:course_id.json" do
        course = Context.first(:context_type => 'course', :id => params['course_id'])
        return error_json("not authorized") unless admin?(params['course_id'])
        return error_json("not found") unless course
        course.allow_student_feeds = params['allow_student_feeds'] == '1' if params['allow_student_feeds']
        course.save
        course.to_json
      end
    
      # delete a feed from the course
      app.delete "/api/v1/:context_type/:context_id/feeds/:feed_id.json" do
        context_type = params['context_type'].sub(/s$/, '')
        params['context_id'] = session['user_id'] if context_type == 'user' && session['user_id'] && params['context_id'] == 'self'
        context = Context.first(:context_type => context_type, :id => params['context_id'])
        cf = ContextFeed.first(:context => context.id, :id => params['feed_id'], :user_id => session['user_id']) if context && session['user_id']
        user = Context.first(:context_type => 'user', :id => session['user_id']) if session['user_id']
        return error_json("not authorized") if context_type == 'course' && (!admin?(params['context_id']) || cf)
        return error_json("not authorized") if context_type == 'user' && params['context_id'].to_i != session['user_id']
        cf ||= ContextFeed.first(:context_id => context.id, :id => params['feed_id']) if context
        return error_json("not found") unless context && cf
        cf.delete_feed
        {:deleted => true}.to_json
      end
    
      # get all feeds for the course or user
      app.get "/api/v1/:context_type/:context_id/feeds.json" do
        context_type = params['context_type'].sub(/s$/, '')
        params['context_id'] = session['user_id'] if params['context_id'] == 'self' && session['user_id'] && context_type == 'user'
        context = Context.first(:context_type => context_type, :id => params['context_id'])
        return error_json("not authorized") if context_type == 'course' && !participant?(params['context_id'])
        return error_json("session required") if !session['user_id']
        return error_json("not authorized") if context_type == 'user' && session['user_id'] != params['context_id'].to_i
        return error_json("not found") unless context
        page = params['page'].to_i
        feeds = context.context_feeds.all(:limit => 26, :offset => (page * 25))
        res = {
          :objects => feeds[0, 25].map(&:as_json)
        }
        if feeds.length > 25
          res[:meta] = {:next => "/api/v1/#{params['context_type']}/#{params['context_id']}/feeds.json?page=#{page + 1}"}
        end
        if page > 0
          res[:meta] ||= {}
          res[:meta][:previous] = "/api/v1/#{params['context_type']}/#{params['context_id']}/feeds.json?page=#{page - 1}"
        end
        res.to_json
      end
    end
    
    module Helpers
      def error_json(str)
        {:error => str}.to_json
      end
    end
  end
  
  register Api
end
