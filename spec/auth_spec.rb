require File.dirname(__FILE__) + '/spec_helper'

describe 'LTI Launch' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  describe "POST lti_launch" do
    it "should fail on invalid signature" do
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(false)
      post "/lti_launch", {}
      last_response.should be_ok
      assert_error_page("Invalid tool launch - unknown tool consumer")
    end
    
    it "should succeed on valid signature" do
      LtiConfig.create(:consumer_key => 'lti', :shared_secret => '123')
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(true)
      IMS::LTI::ToolProvider.any_instance.stub(:roles).and_return(['student'])
      post "/lti_launch", {'oauth_consumer_key' => 'lti', 'tool_consumer_instance_guid' => 'something', 'user_id' => '1', 'context_id' => '2'}
      last_response.should be_redirect
    end
    
    it "should set session parameters" do
      LtiConfig.create(:consumer_key => 'lti', :shared_secret => '123')
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(true)
      IMS::LTI::ToolProvider.any_instance.stub(:roles).and_return(['student'])
      post "/lti_launch", {'oauth_consumer_key' => 'lti', 'tool_consumer_instance_guid' => 'something', 'user_id' => '1', 'context_id' => '2'}
      last_response.should be_redirect
      course = Context.first(:context_type => 'course', :global_id => 'something.2')
      session['user_id'].should == Context.first(:context_type => 'user', :global_id => 'something.1').id
      session['context_id'].should == course.id
      session["permission_for_#{course.id}"].should == 'view'
    end
    
    it "should provision user and course if new" do
      LtiConfig.create(:consumer_key => 'lti', :shared_secret => '123')
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(true)
      IMS::LTI::ToolProvider.any_instance.stub(:roles).and_return(['student'])
      post "/lti_launch", {'oauth_consumer_key' => 'lti', 'tool_consumer_instance_guid' => 'something', 'user_id' => '1', 'context_id' => '2'}
      last_response.should be_redirect
      Context.first(:context_type => 'user', :global_id => 'something.1').should_not be_nil
      Context.first(:context_type => 'course', :global_id => 'something.2').should_not be_nil
    end
    
    it "should use existing user and course if not new" do
      LtiConfig.create(:consumer_key => 'lti', :shared_secret => '123')
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(true)
      IMS::LTI::ToolProvider.any_instance.stub(:roles).and_return(['student'])
      course = Context.create(:context_type => 'course', :global_id => 'something.2')
      user = Context.create(:context_type => 'user', :global_id => 'something.1')
      post "/lti_launch", {'oauth_consumer_key' => 'lti', 'tool_consumer_instance_guid' => 'something', 'user_id' => '1', 'context_id' => '2'}
      last_response.should be_redirect
      session['user_id'].should == user.id
      session['context_id'].should == course.id
    end
    
    it "should redirect to feed page if authorized" do
      LtiConfig.create(:consumer_key => 'lti', :shared_secret => '123')
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(true)
      IMS::LTI::ToolProvider.any_instance.stub(:roles).and_return(['student'])
      post "/lti_launch", {'oauth_consumer_key' => 'lti', 'tool_consumer_instance_guid' => 'something', 'user_id' => '1', 'context_id' => '2'}
      last_response.should be_redirect
      last_response.location.should == "http://example.org/courses/2/feeds"
    end
    
    it "should redirect to selection page if specified" do
      LtiConfig.create(:consumer_key => 'lti', :shared_secret => '123')
      IMS::LTI::ToolProvider.any_instance.stub(:valid_request?).and_return(true)
      IMS::LTI::ToolProvider.any_instance.stub(:roles).and_return(['student'])
      post "/lti_launch", {'oauth_consumer_key' => 'lti', 'tool_consumer_instance_guid' => 'something', 'user_id' => '1', 'context_id' => '2', 'selection_directive' => 'select_link'}
      last_response.should be_redirect
      last_response.location.should == "http://example.org/courses/2/entry_selection"
    end
    
  end  
end
