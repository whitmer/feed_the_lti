require 'sanitize'

module FeedHandler
  def self.get_xml(url)
    uri = URI.parse(url) rescue nil
    return FeedHandler.empty_xml unless uri && uri.respond_to?(:request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request) rescue nil
    return FeedHandler.empty_xml unless response
    xml = Nokogiri::XML(response.body) rescue FeedHandler.empty_xml
    xml = FeedHandler.empty_xml if xml.css("rss,feed").length == 0
    xml
  end
  
  def self.empty_xml
    @empty_xml ||= Nokogiri("")
  end
  
  def self.register_callback(feed, xml, protocol_and_host)
    callback = protocol_and_host + "/api/v1/feeds/#{feed.id}/" + feed.nonce
    hub_url = xml.css("link[rel='hub']")[0]['href'] rescue nil
    params = [
      ['hub.callback', callback],
      ['hub.mode', 'subscribe'],
      ['hub.topic', feed.feed_url],
      ['hub.verify', 'async'],
      ['hub.verify', 'sync']
    ]
    
    return false unless hub_url
    uri = URI.parse(hub_url) rescue nil
    return false unless uri && uri.respond_to?(:request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(params)
    response = http.request(request) rescue nil
    return false unless response

    # don't forget about SSL
    response.code == 204 || response.code == 202
  end
  
  def self.feed_name(xml)
    obj = xml.css('feed > title')[0]
    obj ||= xml.css('rss > channel > title')[0]
    (obj && obj.content) || "Untitled Feed"
  end
  
  def self.identify_feed(xml)
    if xml.children[0].name == 'feed'
      'atom'
    elsif xml.css("rss[version='2.0']").length > 0
      'rss2'
    else
      'unknown'
    end
  end
  
  def self.parse_entries(xml)
    entries = []
    # rss 2.0
    xml.css('item').each do |item|
      obj = {
        :guid => item.css('guid')[0].try(:content),
        :title => sanitize_and_truncate(item.css('title')[0].try(:inner_html) || "No Title"),
        :url => item.css('link')[0].try(:content),
        :short_html => sanitize_and_truncate(CGI.unescape_html(item.css('description')[0].try(:inner_html) || "")),
        :author_name => "Unknown"
      }
      entries << obj if obj[:guid] && obj[:url]
    end
    # atom
    xml.css('entry').each do |entry|
      html = entry.css("content[type='html']")[0].try(:inner_html) || entry.css("content[type='xhtml']")[0].try(:inner_html) || entry.css('summary')[0].try(:inner_html)
      obj = {
        :guid => entry.css('id')[0].try(:content),
        :title => sanitize_and_truncate(entry.css('title')[0].try(:inner_html) || "No Title"),
        :url => (entry.css('link')[0] || {})['href'],
        :short_html => sanitize_and_truncate(html),
        :author_name => entry.css('author name')[0].try(:content) || "Unknown",
        :author_email => entry.css('author email')[0].try(:content)
      }
      entries << obj if obj[:guid] && obj[:url]
    end
    entries
  end
  
  def self.sanitize_and_truncate(html)
    truncate_html(sanitize(html))
  end
  
  def self.sanitize(html)
    html ||= ""
    Sanitize.clean(html, Sanitize::Config::RELAXED)
  end
  
  def self.truncate_html(html)
    options = {:num_words => 50, :ellipsis => "..."}
    doc = Nokogiri::HTML(html)
    options[:max_length] ||= 250
    num_words = options[:num_words] || (options[:max_length] / 5) || 30
    truncate_string = options[:ellipsis]
    truncate_elem = Nokogiri::HTML("<span>" + truncate_string + "</span>").at("span")

    current = doc.children.first
    count = 0

    while true
      # we found a text node
      if current.is_a?(Nokogiri::XML::Text)
        count += current.text.split.length
        # we reached our limit, let's get outta here!
        break if count > num_words
        previous = current
      end

      if current.children.length > 0
        # this node has children, can't be a text node,
        # lets descend and look for text nodes
        current = current.children.first
      elsif !current.next.nil?
        #this has no children, but has a sibling, let's check it out
        current = current.next
      else
        # we are the last child, we need to ascend until we are
        # either done or find a sibling to continue on to
        n = current
        while !n.is_a?(Nokogiri::HTML::Document) and n.parent.next.nil?
          n = n.parent
        end

        # we've reached the top and found no more text nodes, break
        if n.is_a?(Nokogiri::HTML::Document)
          break;
        else
          current = n.parent.next
        end
      end
    end

    if count >= num_words
      unless count == num_words
        new_content = current.text.split

        # If we're here, the last text node we counted eclipsed the number of words
        # that we want, so we need to cut down on words.  The easiest way to think about
        # this is that without this node we'd have fewer words than the limit, so all
        # the previous words plus a limited number of words from this node are needed.
        # We simply need to figure out how many words are needed and grab that many.
        # Then we need to -subtract- an index, because the first word would be index zero.

        # For example, given:
        # <p>Testing this HTML truncater.</p><p>To see if its working.</p>
        # Let's say I want 6 words.  The correct returned string would be:
        # <p>Testing this HTML truncater.</p><p>To see...</p>
        # All the words in both paragraphs = 9
        # The last paragraph is the one that breaks the limit.  How many words would we
        # have without it? 4.  But we want up to 6, so we might as well get that many.
        # 6 - 4 = 2, so we get 2 words from this node, but words #1-2 are indices #0-1, so
        # we subtract 1.  If this gives us -1, we want nothing from this node. So go back to
        # the previous node instead.
        index = num_words-(count-new_content.length)-1
        if index >= 0
          new_content = new_content[0..index]
          current.add_previous_sibling(truncate_elem)
          new_node = Nokogiri::XML::Text.new(new_content.join(' '), doc)
          truncate_elem.add_previous_sibling(new_node)
          current = truncate_elem
        else
          current = previous
          # why would we do this next line? it just ends up xml escaping stuff
          #current.content = current.content
          current.add_next_sibling(truncate_elem)
          current = truncate_elem
        end
      end

      # remove everything else
      while !current.is_a?(Nokogiri::HTML::Document)
        while !current.next.nil?
          current.next.remove
        end
        current = current.parent
      end
    end

    # now we grab the html and not the text.
    # we do first because nokogiri adds html and body tags
    # which we don't want
    res = doc.at_css('body').inner_html rescue nil
    if doc.at_css('body') && doc.at_css('body').children.length == 1 && doc.at_css('body').children[0].name == "p"
      res = doc.at_css('body').children[0].inner_html
    end
    res ||= doc.root.children.first.inner_html rescue ""
  end
  
      html ||= ""
    html
  end
  
  def truncate
end