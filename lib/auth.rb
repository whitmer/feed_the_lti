require 'sinatra/base'

module Sinatra
  module Auth
    # LTI tool launch, makes sure we're oauth-good and then redirects to the magic page
    post "/lti_launch" do
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
        if params['selection_directive']
          redirect to("/courses/#{course.id}/entry_selection")
        else
          redirect to("/courses/#{course.id}/feeds")
        end
      else
        return error("Invalid tool launch - invalid parameters")
      end
    end

  end
  
  register Auth
end
