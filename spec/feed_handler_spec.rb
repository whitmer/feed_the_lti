require File.dirname(__FILE__) + '/spec_helper'
require 'ostruct'

describe FeedHandler do
  include Rack::Test::Methods

  describe "get_feed" do
    it "should fail gracefully on bad URLs" do
      feed_data = FeedHandler.get_feed("bacon")
      feed_data.should == nil

      feed_data = FeedHandler.get_feed("xhttp://wendys.baconator")
      feed_data.should == nil
    end
    
    it "should fail gracefully on empty responses" do
      feed = FeedHandler.parse_feed("")
      feed.should == nil
    end

    it "should fail gracefully on html responses" do
      body = "<html><head></head><body>Bad Stuff</body></html>"
      feed = FeedHandler.parse_feed(body)
      feed.should == nil
    end
    
    it "should fail gracefully on json responses" do
      body = {:text => "ok"}.to_json
      feed = FeedHandler.parse_feed(body)
      feed.should == nil
    end

    it "should fail gracefully on non-feed xml responses" do
      body = "<a><b>asdf</b>jkl</a>"
      feed = FeedHandler.parse_feed(body)
      feed.should == nil
    end

    it "should return a valid xml object" do
      body = atom_example
      feed = FeedHandler.parse_feed(body)
      feed.should_not == true
      feed.should_not == nil
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
      FeedHandler.feed_name(FeedHandler.parse_feed(atom_example)).should == "Example Feed"
    end
    it "should parse rss2 feeds for a name" do
      FeedHandler.feed_name(FeedHandler.parse_feed(rss_example)).should == "RSS Title"
    end
    it "should not error on other xml documents" do
      FeedHandler.feed_name(FeedHandler.parse_feed("<a><title>asdf</title></a>")).should == "Untitled Feed"
    end
  end
  
  describe "identify_feed" do
    it "should recognize valid atom feeds" do
      FeedHandler.identify_feed(FeedHandler.parse_feed(atom_example)).should == "atom"
    end
    
    it "should recognize valid rss2 feeds" do
      FeedHandler.identify_feed(FeedHandler.parse_feed(rss_example)).should == "rss2"
    end

    it "should not recognize bad feeds" do
      FeedHandler.identify_feed(FeedHandler.parse_feed("<a><title>asdf</title></a>")).should == "unknown"
    end
  end
  
  describe "parse_entries" do
    it "should find entry data in a valid atom feed" do
      entries = FeedHandler.parse_entries(FeedHandler.parse_feed(atom_example))
      entries.length.should == 2
      entries[0].should == {
        :guid => "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a",
        :published => Time.parse("2003-12-13 18:30:02 UTC"),
        :title => "Atom-Powered Robots Run Amok",
        :url => "http://example.org/2003/12/13/atom03.html",
        :short_html => "Some text.",
        :author_name => "John Doe"
      }
      entries[1].should == {
        :guid => "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a2",
        :title => "No Title",
        :published => nil,
        :url => "http://example.org/2003/12/13/atom03",
        :short_html => "",
        :author_name => "Unknown"
      }
    end
    
    it "should find entry data in a valid rss2 feed" do
      entries = FeedHandler.parse_entries(FeedHandler.parse_feed(rss_example))
      entries.length.should == 2
      entries[0].should == {
        :guid => "unique string per item",
        :published => Time.parse("2009-09-06 16:45:00 UTC"),
        :title => "Example entry",
        :url => "http://www.wikipedia.org/",
        :short_html => "Here is some text containing an interesting description.",
        :author_name => "Unknown"
      }
      entries[1].should == {
        :guid => "unique string per item",
        :title => "No Title",
        :published => nil,
        :url => "http://www.wikipedia.org/",
        :short_html => "",
        :author_name => "Unknown"
      }
    end
    
    it "should ignore unnecessary values" do
      entries = FeedHandler.parse_entries(FeedHandler.parse_feed("<entry><item><asdf></bob>"))
      entries.length.should == 0
    end
    
    it "should truncate and sanitize content" do
      entries = FeedHandler.parse_entries(FeedHandler.parse_feed(long_atom_example))
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
      FeedHandler.sanitize_and_truncate("")
    end
    
    it "should sanitize non-whitelisted tags" do
      FeedHandler.sanitize_and_truncate("<script>test</script>").should == "test"
      FeedHandler.sanitize_and_truncate("<iframe></iframe>some <b>words</b><pre>asdf</pre>").should == "<p>some <b>words</b></p>\n<pre>asdf</pre>"
    end
    
    it "should not truncate within an html tag" do
      FeedHandler.sanitize_and_truncate("a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text <img src=\"http:/www.example.com/images/with/long/paths/are/cool.png\"> a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text ").should == "a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot of text a lot<span>...</span>"
    end
  end
end
