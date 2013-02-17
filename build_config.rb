require './feed_the_lti'
conf = LtiConfig.generate
puts "Key:    #{conf.consumer_key}"
puts "Secret: #{conf.shared_secret}"