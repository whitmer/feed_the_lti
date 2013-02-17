ENV['RACK_ENV']='test'
RACK_ENV='test'
require 'rspec'
require 'rack/test'
require 'json'
require './feed_the_lti'

set :environment, :test

RSpec.configure do |config|
  config.before(:each) { 
    DataMapper.auto_migrate! 
  }
end

def session
  last_request.env['rack.session']
end

def assert_error_page(msg)
  last_response.body.should match(msg)
end

def course
  @course = Context.new(:context_type => 'course')
  @course.name = "New Course"
  @course.global_id = "asdfyuiop"
  @course.save
  @course
end

def feed
  @feed = Feed.new
  @feed.name = "My Feed"
  @feed.nonce = "1234"
  @feed.feed_url = "http://example.com"
  @feed.feed_type = 'atom'
  @feed.save
  @feed.reload.id.should_not be_nil
  @feed
end

def atom_example(with_hub=false)
  str = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
        <title>Example Feed</title>
        <subtitle>A subtitle.</subtitle>
        <link href="http://example.org/feed/" rel="self"/>
        <link href="http://example.org/"/>
  EOF
  if with_hub
    str += <<-EOF
      <link href="http://example.org/hub" rel="hub"/>
    EOF
  end
  str += <<-EOF
        <id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>
        <updated>2003-12-13T18:30:02Z</updated>
        <entry>
                <title>Atom-Powered Robots Run Amok</title>
                <link href="http://example.org/2003/12/13/atom03"/>
                <link rel="alternate" type="text/html" href="http://example.org/2003/12/13/atom03.html"/>
                <link rel="edit" href="http://example.org/2003/12/13/atom03/edit"/>
                <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
                <updated>2003-12-13T18:30:02Z</updated>
                <summary>Some text.</summary>
                <author>
                      <name>John Doe</name>
                      <email>johndoe@example.com</email>
                </author>
        </entry>
        <entry>
        </entry>
        <entry>
                <link href="http://example.org/2003/12/13/atom03"/>
                <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a2</id>
        </entry>
</feed>
  EOF
end

def long_atom_example
  <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
        <title>Example Feed</title>
        <subtitle>A subtitle.</subtitle>
        <link href="http://example.org/feed/" rel="self"/>
        <link href="http://example.org/"/>
        <id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>
        <updated>2003-12-13T18:30:02Z</updated>
        <entry>
                <title>Atom-Powered Robots Run Amok</title>
                <link href="http://example.org/2003/12/13/atom03"/>
                <link rel="alternate" type="text/html" href="http://example.org/2003/12/13/atom03.html"/>
                <link rel="edit" href="http://example.org/2003/12/13/atom03/edit"/>
                <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
                <updated>2003-12-13T18:30:02Z</updated>
                <summary>Some text.</summary>
                <author>
                      <name>John Doe</name>
                      <email>johndoe@example.com</email>
                </author>
                <content type='html'>
                  <div>
                    <iframe src='/iframe.html'/>
                    <p>This is a lot of text 
                      <a href="http://www.google.com"> 
                        Google Link <img src="http://pictures.com/this/is/not/a/picture.png"/>
                      </a>
                    </p>
                    <p>This is a lot of text 
                      <a href="javascript: alert('asdf');"> 
                        Google Link <img src="http://pictures.com/this/is/not/a/picture.png"/>
                      </a>
                    </p>
                    <p>This is a lot of text. This is a lot of text. This is a lot of text. 
                      This is a lot of text. This is a lot of text. This is a lot of text. This is a lot of text. 
                      This is a lot of text. This is a lot of text. This is a lot of text. This is a lot of text. 
                      This is a lot of text. This is a lot of text. This is a lot of text. This is a lot of text. 
                      This is a lot of text. This is a lot of text. This is a lot of text. This is a lot of text. 
                      This is a lot of text. This is a lot of text. This is a lot of text. This is a lot of text. 
                      This is a lot of text. This is a lot of text. This is a lot of text. This is a lot of text. 
                    </p>
                    <p>truncated!</p>
                  </div>
                </content>
        </entry>
</feed>
  EOF
end

def rss_example
  <<-EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
        <title>RSS Title</title>
        <description>This is an example of an RSS feed</description>
        <link>http://www.someexamplerssdomain.com/main.html</link>
        <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000 </lastBuildDate>
        <pubDate>Mon, 06 Sep 2009 16:45:00 +0000 </pubDate>
        <ttl>1800</ttl>
 
        <item>
                <title>Example entry</title>
                <description>Here is some text containing an interesting description.</description>
                <link>http://www.wikipedia.org/</link>
                <guid>unique string per item</guid>
                <pubDate>Mon, 06 Sep 2009 16:45:00 +0000 </pubDate>
        </item>
        <item>
                <guid>unique string per item</guid>
        </item>
        <item>
                <link>http://www.wikipedia.org/</link>
                <guid>unique string per item</guid>
        </item>
 
</channel>
</rss>
  EOF
end