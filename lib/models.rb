require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'sinatra/base'
require 'time'

# TODO: figure out indexes in postgres+datamapper

class Feed
  include DataMapper::Resource
  property :id, Serial
  property :last_checked_at, DateTime
  property :name, String
  property :nonce, String
  property :feed_url, String, :length => 4096
  property :feed_type, String
  property :entry_count, Integer
  property :callback_enabled, Boolean
  before :save, :generate_defaults
  has n, :feed_entries
  has n, :context_feeds
  
  def generate_defaults
    self.nonce ||= Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)
  end
  
  def disable
    # TODO: add support for unsubscription according to pubsubhubbub spec
  end
  
  def check_for_entries(feed_data=nil)
    if !feed_data
      feed_data = FeedHandler.get_feed(self.feed_url)
    end
    entries = []
    FeedHandler.parse_entries(feed_data).each do |e|
      entry = FeedEntry.first_or_new(:feed_id => self.id, :guid => e[:guid])
      entry.title = (e[:title] || "")[0, 50]
      entry.url = e[:url]
      entry.author_name = e[:author_name]
      entry.short_html = e[:short_html]
      entry.created_at = e[:published] || entry.created_at || DateTime.now
      entry.save
      entries << entry
    end
    self.last_checked_at = DateTime.now
    self.entry_count = self.feed_entries.count
    self.save
    entries.length
  end
end

class Context
  include DataMapper::Resource
  property :id, Serial
  property :name, String, :length => 4096
  property :context_type, String, :index => true
  property :allow_student_feeds, Boolean
  property :global_id, String, :length => 512, :index => true
  property :image_url, String, :length => 4096
  property :lti_config_id, Integer
  has n, :context_feeds
  has n, :feeds, :through => :context_feeds, :order => :name
  
  def feed_ids
    self.context_feeds.map(&:id).uniq
  end
  
  def path
    "#{context_type}s/#{id}"
  end
  
  def readable_type
    context_type == 'course' ? "Course" : "User"
  end
  
  def feed_count
    cnt = self.context_feeds.count
    "#{cnt} #{readable_type} Feed" + (cnt == 1 ? "" : "s")
  end
  
  def results_for(page, feed_id='all')
    entries = []
    feeds = self.context_feeds
    if feed_id != 'all'
      feeds = feeds.select{|f| f.id == feed_id.to_i }
    end
    filters = {}
    feed_ids = feeds.map(&:feed_id)
    feeds.each{|f| filters[f.feed_id] = f.filter if feed_ids.include?(f.feed_id) }
    total = 0
    FeedEntry.all(:limit => 26, :offset => (page * 25), :feed_id => feed_ids, :order => :created_at.desc).each do |entry|
      filter = filters[entry.feed_id]
      total += 1
      entries << entry.as_json if entry.matches_filter?(filter)
    end
    res = {
      :objects => entries[0, 25],
      :context => self.as_json
    }
    res[:feeds] = feeds.map(&:as_json)
    res[:next] = total > 25
    res
  end
  
  def create_feed(url, filter, user_id, protocol_and_host)
    feed = Feed.first_or_new(:feed_url => url) if url
    feed_data = FeedHandler.get_feed(feed.feed_url) if feed && feed.feed_url
    feed.feed_type = FeedHandler.identify_feed(feed_data) if feed_data
    if !feed || !feed.feed_type || feed.feed_type == 'unknown'
      return nil
    end
    feed.name = FeedHandler.feed_name(feed_data) || "Feed"
    feed.save
    feed.callback_enabled = FeedHandler.register_callback(feed, feed_data, protocol_and_host) if !feed.callback_enabled
    feed.check_for_entries(feed_data) unless feed.last_checked_at && feed.last_checked_at > (Time.now - 60).to_datetime
    cf = ContextFeed.first_or_new(:context_id => self.id, :feed_id => feed.id, :filter => filter)
    cf.user_id = user_id
    cf.filter = filter if filter && filter.length > 0
    cf.save
    cf
  end

  def as_json
    {
      :id => self.id,
      :context_type => self.context_type,
      :allow_student_feeds => !!self.allow_student_feeds,
      :feed_ids => self.feed_ids
    }
  end
  
  def to_json
    as_json.to_json
  end
end

class ContextFeed
  include DataMapper::Resource
  property :id, Serial
  property :context_id, Integer, :index => true
  property :feed_id, Integer, :index => true
  property :user_id, Integer
  property :filter, String
  belongs_to :feed
  belongs_to :context
  
  def delete_feed
    if self.feed.context_feeds.length == 1
      self.feed.feed_entries.destroy
      self.feed.destroy
    end
    self.destroy
  end
  
  def as_json
    feed = self.feed
    {
      :id => self.id,
      :raw_feed_id => self.feed_id,
      :last_checked => (feed.last_checked_at && feed.last_checked_at.strftime("%Y-%m-%d %l:%M%P")),
      :name => feed.name,
      :feed_url => feed.feed_url,
      :filter => self.filter,
      :feed_type => feed.feed_type,
      :entry_count => feed.entry_count || 0,
      :callback_enabled => feed.callback_enabled,
      :nonce => feed.nonce
    }
  end
  
  def to_json
    as_json.to_json
  end
end

class FeedEntry
  include DataMapper::Resource
  property :id, Serial
  property :feed_id, Integer, :index => true
  property :title, String
  property :url, String, :length => 4096
  property :author_name, String
  property :short_html, Text
  property :created_at, DateTime
  property :guid, String, :length => 512, :index => true
  belongs_to :feed
  
  def matches_filter?(filter)
    return true unless filter
    return (self.title || "").match(Regexp.new(filter, "i"))
  end
  
  def as_json
    {
      :title => self.title,
      :id => self.id,
      :url => self.url,
      :short_html => self.short_html,
      :created => self.created_at && self.created_at.strftime("%Y-%m-%d %l:%M%P"),
      :author_name => self.author_name,
      :raw_feed_id => self.feed_id,
      :feed_name => self.feed.name
    }
  end
  
  def to_json
    as_json.to_json
  end
end

class LtiConfig
  include DataMapper::Resource
  property :id, Serial
  property :app_name, String
  property :contact_email, String
  property :consumer_key, String, :length => 512
  property :shared_secret, String, :length => 512
  
  def self.generate(name, key=nil)
    conf = LtiConfig.new
    conf.app_name = name
    conf.consumer_key = (key || Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)).to_s
    conf.shared_secret = Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s + conf.consumer_key)
    conf.save
    conf
  end
end
