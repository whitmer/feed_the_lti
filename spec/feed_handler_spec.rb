require File.dirname(__FILE__) + '/spec_helper'
require 'ostruct'

describe FeedHandler do
  include Rack::Test::Methods

  describe "get_xml" do
    it "should handle ssl" do
      Net::HTTP.any_instance.should_receive("use_ssl=".to_sym).with(true).and_return(true)
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:body => ""}))
      xml = FeedHandler.get_xml("https://www.google.com")
    end
    
    it "should fail gracefully on bad URLs" do
      xml = FeedHandler.get_xml("bacon")
      xml.to_s.should == "<?xml version=\"1.0\"?>\n"

      xml = FeedHandler.get_xml("http://wendys.baconator")
      xml.to_s.should == "<?xml version=\"1.0\"?>\n"
    end
    
    it "should fail gracefully on empty responses" do
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:body => ""}))
      xml = FeedHandler.get_xml("http://www.google.com")
      xml.to_s.should == "<?xml version=\"1.0\"?>\n"
    end

    it "should fail gracefully on html responses" do
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:body => "<html><head></head><body>Bad Stuff</body></html>"}))
      xml = FeedHandler.get_xml("http://www.google.com")
      xml.to_s.should == "<?xml version=\"1.0\"?>\n"
    end
    
    it "should fail gracefully on json responses" do
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:body => {:text => "ok"}.to_json}))
      xml = FeedHandler.get_xml("http://www.google.com")
      xml.to_s.should == "<?xml version=\"1.0\"?>\n"
    end

    it "should fail gracefully on non-feed xml responses" do
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:body => "<a><b>asdf</b>jkl</a>"}))
      xml = FeedHandler.get_xml("http://www.google.com")
      xml.to_s.should == "<?xml version=\"1.0\"?>\n"
    end

    it "should return a valid xml object" do
      Net::HTTP.any_instance.should_receive(:request).and_return(OpenStruct.new({:body => atom_example}))
      xml = FeedHandler.get_xml("http://www.google.com")
      xml.to_s.should == atom_example
    end
  end
  
  describe "register_callback" do
    it "should register http hubs"
    it "should register https hubs"
    it "should send valid parameters"
    it "should return success on 204 or 202 response codes"
    it "should return failure on any other response codes"
  end
  
  describe "feed_name" do
    it "should parse atom feeds for a name" do
      FeedHandler.feed_name(Nokogiri::XML(atom_example)).should == "Example Feed"
    end
    it "should parse rss2 feeds for a name" do
      FeedHandler.feed_name(Nokogiri::XML(rss_example)).should == "RSS Title"
    end
    it "should not error on other xml documents" do
      FeedHandler.feed_name(Nokogiri::XML("<a><title>asdf</title></a>")).should == "Untitled Feed"
    end
  end
  
  describe "identify_feed" do
    it "should recognize valid atom feeds" do
      FeedHandler.identify_feed(Nokogiri::XML(atom_example)).should == "atom"
    end
    
    it "should recognize valid rss2 feeds" do
      FeedHandler.identify_feed(Nokogiri::XML(rss_example)).should == "rss2"
    end

    it "should not recognize bad feeds" do
      FeedHandler.identify_feed(Nokogiri::XML("<a><title>asdf</title></a>")).should == "unknown"
    end
  end
  
  describe "parse_entries" do
    it "should find entry data in a valid atom feed" do
      entries = FeedHandler.parse_entries(Nokogiri::XML(atom_example))
      entries.length.should == 2
      entries[0].should == {
        :guid => "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a",
        :title => "Atom-Powered Robots Run Amok",
        :url => "http://example.org/2003/12/13/atom03",
        :short_html => "Some text.",
        :author_name => "John Doe",
        :author_email => "johndoe@example.com"
      }
      entries[1].should == {
        :guid => "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a2",
        :title => "No Title",
        :url => "http://example.org/2003/12/13/atom03",
        :short_html => "",
        :author_name => "Unknown",
        :author_email => nil
      }
    end
    
    it "should find entry data in a valid rss2 feed" do
      entries = FeedHandler.parse_entries(Nokogiri::XML(rss_example))
      entries.length.should == 2
      entries[0].should == {
        :guid => "unique string per item",
        :title => "Example entry",
        :url => "http://www.wikipedia.org/",
        :short_html => "Here is some text containing an interesting description.",
        :author_name => "Unknown"
      }
      entries[1].should == {
        :guid => "unique string per item",
        :title => "No Title",
        :url => "http://www.wikipedia.org/",
        :short_html => "",
        :author_name => "Unknown"
      }
    end
    
    it "should ignore unnecessary values" do
      entries = FeedHandler.parse_entries(Nokogiri::XML("<entry><item><asdf></bob>"))
      entries.length.should == 0
    end
    
    it "should truncate and sanitize content" do
      entries = FeedHandler.parse_entries(Nokogiri::XML(long_atom_example))
      entries.length.should == 1
      entries[0][:short_html].length.should < 1000
      entries[0][:short_html].should_not match(/iframe/)
      entries[0][:short_html].should_not match(/truncated/)
      entries[0][:short_html].should_not match(/alert/)
    end
    
  end
  
  describe "sanitize_and_truncate" do
    it "should truncate plaintext" do
      FeedHandler.sanitize_and_truncate("bob").should == "bob"
      FeedHandler.sanitize_and_truncate("this is some text").should == "this is some text"
      FeedHandler.sanitize_and_truncate("a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text ").should == "a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot<span>...</span>"
    end
    
    it "should truncate rich html" do
      FeedHandler.sanitize_and_truncate("<b>bob</b>").should == "<b>bob</b>"
      FeedHandler.sanitize_and_truncate("<img src='http://www.google.com' title='a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text'/>").should == "<img src=\"http://www.google.com\" title=\"a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text\">"
    end
    
    it "should sanitize non-whitelisted tags" do
      FeedHandler.sanitize_and_truncate("<script>test</script>").should == "test"
      FeedHandler.sanitize_and_truncate("<iframe>some words<pre>asdf</pre>").should == "<p>some words</p>\n<pre>asdf</pre>"
    end
    
    it "should not truncate within an html tag" do
      FeedHandler.sanitize_and_truncate("a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text <img src=\"http:/www.example.com/images/with/long/paths/are/cool.png\"> a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text ").should == "a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text <img src=\"http:/www.example.com/images/with/long/paths/are/cool.png\">a lot<span>...</span>"
    end
  end
end
