require 'sinatra/base'

module Sinatra
  module Auth
    def self.registered(app)
      app.helpers Auth::Helpers
      
      # LTI tool launch, makes sure we're oauth-good and then redirects to the magic page
      app.post "/lti_launch" do
        key = params['oauth_consumer_key']
        config = LtiConfig.first(:consumer_key => key)
        if !config || !params['tool_consumer_instance_guid']
          return error("Invalid tool launch - unknown tool consumer")
        end
        instance = params['tool_consumer_instance_guid']
        provider = IMS::LTI::ToolProvider.new(key, config.shared_secret, params)
        if provider.valid_request?(request)
          user_id = instance + "." + params['user_id']
          user_id = "bob" if false # placeholder for Canvas global user information
          course_id = params['tool_consumer_instance_guid'] + "." + params['context_id']
          user = Context.first(:global_id => user_id, :context_type => 'user')
          course = Context.first(:global_id => course_id, :context_type => 'course')
          if !user
            user = Context.new(:global_id => user_id, :context_type => 'user')
            user.lti_config_id = config.id
            user.name = params['lis_person_name_full'] || "User"
            user.image_url  = params['user_image'] || "/user_fallback.png"
            user.save
          end
          if !course
            course = Context.new(:global_id => course_id, :context_type => 'course')
            course.lti_config_id = config.id
            course.name = params['context_title'] || "Course"
            course.image_url = "/course_fallback.png"
            course.save
          end
        
          session['user_id'] = user.id
          session['context_id'] = course.id
          # check if they're a teacher or not
          session["permission_for_#{course.id}"] = 'view'
          session["permission_for_#{course.id}"] = 'edit' if provider.roles.include?('instructor') || provider.roles.include?('contentdeveloper') || provider.roles.include?('urn:lti:instrole:ims/lis/administrator') || provider.roles.include?('administrator')
          if params['selection_directive'] == 'submit_homework' || params['ext_content_intended_use'] == 'homework'
            redirect to("/courses/#{course.id}/user_entry_selection?return_url=" + CGI.escape(params['launch_presentation_return_url']))
          elsif params['selection_directive']
            redirect to("/courses/#{course.id}/entry_selection?return_url=" + CGI.escape(params['launch_presentation_return_url']))
          else
            redirect to("/courses/#{course.id}/feeds")
          end
        else
          return error("Invalid tool launch - invalid parameters")
        end
      end

      app.get "/login" do
        request_token = consumer.get_request_token(:oauth_callback => "#{request.scheme}://#{request.host_with_port}/login_success")
        if request_token.token && request_token.secret
          session[:oauth_token] = request_token.token
          session[:oauth_token_secret] = request_token.secret
        else
          return "Authorization failed"
        end
        redirect to("https://api.twitter.com/oauth/authenticate?oauth_token=#{request_token.token}")
      end
  
      app.get "/login_success" do
        verifier = params[:oauth_verifier]
        if params[:oauth_token] != session[:oauth_token]
          return "Authorization failed"
        end
        request_token = OAuth::RequestToken.new(consumer,
          session[:oauth_token],
          session[:oauth_token_secret]
        )
        access_token = request_token.get_access_token(:oauth_verifier => verifier)
        screen_name = access_token.params['screen_name']
    
        if !screen_name
          return "Authorization failed"
        end
    
        @conf = LtiConfig.first(:consumer_key => screen_name)
        @conf ||= LtiConfig.generate("Twitter for @#{screen_name}", screen_name)
        erb :config_tokens
      end
    end
    
    module Helpers
      def consumer
        consumer ||= OAuth::Consumer.new(twitter_config.consumer_key, twitter_config.shared_secret, {
          :site => "http://api.twitter.com",
          :request_token_path => "/oauth/request_token",
          :access_token_path => "/oauth/access_token",
          :authorize_path=> "/oauth/authorize",
          :signature_method => "HMAC-SHA1"
        })
      end
    
      def twitter_config
        @@twitter_config ||= LtiConfig.first(:app_name => 'twitter_for_login')
      end
    end
  end

  register Auth
end
