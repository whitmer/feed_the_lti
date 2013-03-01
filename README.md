Feed The LTI
---------------------------
This is an LTI-enabled service that allows you to 
specify RSS and Atom feeds that will be aggregated
within a launched context. Feeds can be added by
instructors, or optionally by students.

In the future, this will also allow students to 
track their personal blog feeds and turn in homework
directly from those feeds.

This is a sinatra app. If you don't know what that 
means you'll want to learn before you try to set it
up yourself.

Once you're set up, you can add an LtiConfig record
with an app name of "twitter_for_login" and OAuth
keys and secrets from dev.twitter.com to let users
create their own LTI credentials using just a Twitter
account. The callback_url should be set to `/login_success`