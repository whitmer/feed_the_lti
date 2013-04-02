require 'sinatra/base'

module Sinatra
  module Views
    get "/" do
      erb :index
    end
    
    get "/feed_the_lti.xml" do
      response.headers['Content-Type'] = "text/xml"
      erb :config_xml, :layout => false
    end
    
    get "/courses/:course_id/feeds" do
      return error("Not authorized") unless participant?(params[:course_id])
      @course = Context.first(:context_type => 'course', :id => params['course_id'])
      @user = Context.first(:context_type => 'user', :id => session['user_id'])
      erb :course_feeds
    end
    
    get "/courses/:course_id/entry_selection" do
      # retrieve course and user feeds so the user can pick a specific entry to link to
      return error("Not authorized") unless participant?(params[:course_id])
      @context = Course.first(:id => params['course_id'])
      @user = Context.first(:context_type => 'user', :id => session['user_id'])
      erb :entry_selection
    end
    
    get "/courses/:course_id/user_entry_selection" do
      # retrieve course and user feeds so the user can pick a specific entry to link to
      return error("Not authorized") unless participant?(params[:course_id])
      @context = Course.first(:id => params['course_id'])
      @user = Context.first(:context_type => 'user', :id => session['user_id'])
      erb :user_feeds
    end
        
    helpers do
      def admin?(course_id)
        session["permission_for_#{course_id}"] == 'edit'
      end
      
      def participant?(course_id)
        !!session["permission_for_#{course_id}"]
      end
      
      def error(text)
        message(text)
      end
      
      def message(text)
        @message = text
        return erb :message
      end
    end
  end
  
  register Views
end
