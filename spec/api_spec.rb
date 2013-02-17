require File.dirname(__FILE__) + '/spec_helper'

describe 'API calls' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
# get feed entries for the specified course, possibly filtered to a specific feed id
#     get "/api/v1/courses/:course_id/entries.json" do
#       check_course_permission(params['course_id'])
#       course = Course.first(:id => params['course_id'])
#       page = params['page'].to_i
#       entries = FeedEntry.results_for(course, page)
#       if entries.delete(:next)
#         entries[:meta] = {:next => "/api/v1/courses/#{course.id}/entries.json?page=#{page + 1}"}
#       end
#       if entries.delete(:prev)
#         entries[:meta] ||= {}
#         entries[:meta][:previous] = "/api/v1/courses/#{course.id}/entries.json?page=#{page - 1}"
#       end
#       entries.to_json
#     end
    
  describe "GET course entries" do
    it "should error if the course is not found"
    it "should error if not authorized"
    it "should return feed results"
    it "should return paginated results"
  end
  
  describe "GET pubsubhubbub confirmation" do
    it "should error if invalid feed" do
      feed
      get "/api/v1/feeds/#{@feed.id}x/#{@feed.nonce}.json"
      last_response.should be_ok
      last_response.body.should == "not found"
    end
    
    it "should error if invalid nonce" do
      feed
      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}x.json"
      last_response.should be_ok
      last_response.body.should == "not found"
    end
    
    it "should require hub.mode" do
      feed
      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.challenge=asdf"
      last_response.should be_ok
      last_response.body.should == "not found"
    end
    
    it "should return valid challenge response" do
      feed
      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.mode=subscribe&hub.challenge=asdf"
      last_response.should be_ok
      last_response.body.should == "asdf"

      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.mode=subscribe"
      last_response.should be_ok
      last_response.body.should == "no challenge provided"
    end
    
    it "should disable on unsubscribe" do
      Feed.any_instance.should_receive(:disable).and_return(true)
      feed
      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.mode=unsubscribe&hub.challenge=asdf"
      last_response.should be_ok
      last_response.body.should == "asdf"
    end
    
    it "should respond multiple times" do
      feed
      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.mode=subscribe&hub.challenge=asdf"
      last_response.should be_ok
      last_response.body.should == "asdf"

      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.mode=subscribe&hub.challenge=jkl"
      last_response.should be_ok
      last_response.body.should == "jkl"

      get "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json?hub.mode=subscribe&hub.challenge=qwert"
      last_response.should be_ok
      last_response.body.should == "qwert"
    end
  end
  
  describe "POST pubsubhubbub callback" do
    it "should error if invalid feed" do
      feed
      post "/api/v1/feeds/#{@feed.id}x/#{@feed.nonce}.json"
      last_response.should be_ok
      last_response.body.should == {:found => false, :new_entries => 0, :feed => nil}.to_json
    end
    
    it "should error if invlaid nonce" do
      feed
      post "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}x.json"
      last_response.should be_ok
      last_response.body.should == {:found => false, :new_entries => 0, :feed => nil}.to_json
    end
    
    it "should update feed on valid request" do
      feed
      Feed.any_instance.should_receive(:check_for_entries).and_return(5)
      post "/api/v1/feeds/#{@feed.id}/#{@feed.nonce}.json"
      last_response.should be_ok
      last_response.body.should == {:found => true, :new_entries => 5, :feed => @feed.as_json}.to_json
    end
  end
  
  describe "POST add feed" do
    it "should require permission"
    it "should allow admins to add feeds" do
      course
      post "/api/v1/courses/#{@course.id}/feeds.json", {}, 'rack.session' => {"permission_for_#{@course.id}" => 'edit'}
    end
    it "should allow students to add feeds if permitted"    
  end
  
  describe "DELETE remove feed" do
    it "should require permission"
    it "should remove feeds if authorized"
    it "should only remove one instance of the same feed"
    it "should allow users to delete feeds they added themselves"
  end
  
# get feed entries for the specified user, possibly filtered to a specific feed id
#       get "/api/v1/users/:user_id/entries.json" do
#         params['user_id'] = session['user_id'] if params['user_id'] == 'self'
#         return error("Session required") unless session['user_id']
#         return error("Not authorized") unless session['user_id'] == params['user_id']
#       end
#   
  describe "GET user entries" do
    it "should error if no session"
    it "should error if not the current user"
    it "should return feed if valid"
    it "should return paginated results"
  end
  
end
