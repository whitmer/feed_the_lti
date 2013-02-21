require File.dirname(__FILE__) + '/spec_helper'
require 'ostruct'

describe 'Data models' do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  describe "Feed" do
    describe "check_for_entries" do
      it "should add feed entries from valid xml"
      it "should ignore invalid entries from valid xml"
      it "should fail gracefully on invalid xml"
    end
    
    it "should serialize to json correctly"
  end
  
  describe "FeedEntry" do
    it "should serialize to json correctly"
    it "should check filter matches" do
      fe = FeedEntry.new(:title => "this is my text For Sure")
      fe.matches_filter?(nil).should == true
    end
  end
  
  describe "Context" do
    describe "create_feed" do
      it "should allow creating a feed from params" do
        course
        params = {
          'url' => 'http://example.com/feed.xml'
        }
        FeedHandler.should_receive(:get_xml).with(params['url']).and_return(Nokogiri::XML(atom_example))
        cf = @course.create_feed(params['url'], nil, 1, "http://example.com")
        feed = cf.feed
        feed.should_not be_nil
        feed.feed_url.should == params['url']
        feed.name.should == "Example Feed"
        feed.callback_enabled.should == false
        feed.entry_count.should == 2
        feed.feed_entries.count.should == 2
        cf.context_id.should == @course.id
        cf.feed_id.should == feed.id
        cf.filter.should be_nil
      end
      
      it "should remember set filter" do
        course
        params = {
          'url' => 'http://example.com/feed.xml'
        }
        FeedHandler.should_receive(:get_xml).with(params['url']).and_return(Nokogiri::XML(atom_example))
        feed = @course.create_feed(params['url'], 'friends', nil, "http://example.com")
        feed.should_not be_nil
        cf = ContextFeed.last
        cf.context_id.should == @course.id
        cf.feed_id.should == feed.id
        cf.filter.should == 'friends'
      end
      
      it "should find valid hub for callbacks" do
        course
        params = {
          'url' => 'http://example.com/feed.xml'
        }
        FeedHandler.should_receive(:get_xml).with(params['url']).and_return(Nokogiri::XML(atom_example(true)))
        Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:code => 202}))
        cf = @course.create_feed(params['url'], nil, nil, "http://example.com")
        feed = cf.feed
        feed.should_not be_nil
        feed.feed_url.should == params['url']
        feed.name.should == "Example Feed"
        feed.callback_enabled.should == true
        feed.entry_count.should == 2
        feed.feed_entries.count.should == 2
        cf.context_id.should == @course.id
        cf.feed_id.should == feed.id
        cf.filter.should be_nil
      end
      
      it "should fail gracefully if no context is provided" do
        course
        params = {
          'url' => 'http://example.com/feed.xml'
        }
        FeedHandler.should_receive(:get_xml).with(params['url']).and_return(nil)
        feed = @course.create_feed(params['url'], nil, nil, "http://example.com")
        feed.should be_nil
      end
      
      it "should fail gracefully if no params" do
        course
        feed = @course.create_feed(nil, nil, nil, "http://example.com")
        feed.should be_nil
      end
    end

    describe "results_for" do
      it "should aggregate results across feeds"
      it "should paginage results across feeds"
    end
    
    it "should serialize to json correctly"
  end
end
