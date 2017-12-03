
# dHdlZXRGTSB2NCBieSBkYXNpbmtpbmcgLSBtYWRlIGluIDIwMTYtMTcgd2l0aCA8Mw==
@version = 'tweetFM_v4'

require 'yaml'
require 'twitter'
require 'lastfm'
require 'oauth'

# only needed for some ruby installations on windows, when you get a
# certificate error (fuck that)
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# ===== twitter_auth =====
# wooooooah! api keys!
# those are public anyway, so it doesn't matter posting them publicly. :)
@Twitter = Twitter::REST::Client.new do |config|
  config.consumer_key    = '4iTHA7VaA85qX0gaIT6fskn9f'
  config.consumer_secret = '3GQIVok9vUqob30DfQlghKLM7oACHqKaJtI1YMi90LfKI7a1KT'
end
# ===== twitter_auth_end =====

# ===== lastfm_auth =====
# especially those, because you can't create an app on last.fm for MONTHS now.
# you're welcome.
@lastfm = Lastfm.new(
  'd40320e36eca2707150f55723630436e',
  'aff6f8a58d4ad1a937e0128a83dec486'
)
# ===== lastfm_auth_end =====

# This function initialises the $config hash with the values from config.yml
def init_existing
  # load the existing config to check it's contents
  $config = YAML.load_file(File.expand_path('../config.yml', __FILE__))

  # search for revision. this procedure is futureproof by increasing the number!
  # so smart!!
  # older versions of tweetFM didn't have this config entry, so it will directly
  # identify those configs
  # those older versions use other keys and general entry names, so we want them
  # gone.
  if $config[:revision] != 1
    puts ''
    puts "Welcome to #{@version}! Looks like your update was successful, but we're not done yet."
    puts 'Your existing configuration is based on an older installation of tweetFM.'
    puts 'A new configuration will be created, but before that, we need to delete the old one.'
    puts 'If you have any emotional connection to it, create a backup now.'
    puts "When you're done, or you don't care, press enter."
    $stdin.gets.strip         # wait for enter press
    File.delete('config.yml') # delete old config
    $config = {}              # zero the variable
    return setup              # rerun setup for configuring the new config file
  end

  # config is found which is up-to-date. it's configurations will be set
  # adding twitter tokens from the valid config
  @Twitter.access_token = $config[:twitter_token]
  @Twitter.access_token_secret = $config[:twitter_token_secret]
  # and the lastfm-username for parsing the latest scrobbles
  @lastfmuser = $config[:lastfm_user]
  return unless $config[:url]
  # resetting the url in the profile with every start of tweetFM, heheheh
  @Twitter.update_profile(url: 'https://github.com/dasinking/tweetFM/')
end

# This function authenticates the user with twitter, sets the LastFM user name,
# creates a config and whatnot.
def init_new
  puts ''
  puts 'Welcome, new user of tweetFM!'
  puts "Before we can start spamming you and your friends' timeline, we need to configure some things."
  puts "It won't take long!"

  $config = {} # opening the hash for incoming entries
  # it's an hash, because we'll save those settings to an external file later.
  # it's easier this way.
  init_new_twitter_auth
  init_new_lastfm_username
  init_new_sourcecode_link
  init_new_create_config
end

# This function initialises the user with Twitter.
def init_new_twitter_auth
  # ===== twitter_auth =====
  puts ''
  puts 'First we need access to Twitter.'

  # define where to send the request and its parameters
  consumer = OAuth::Consumer.new(
    @Twitter.consumer_key,
    @Twitter.consumer_secret,
    site: 'https://api.twitter.com'
  )
  # requesting and saving first oauth answer
  request_token = consumer.get_request_token(oauth_callback: @callback_url)

  # saving the auth url separately
  url = request_token.authorize_url(oauth_callback: @callback_url)

  puts "Open this URL in a browser: #{url}"
  pin = ''                  # init pin variable (zeroing)
  until pin =~ /^\d+$/      # loop for typing in the auth pin
    print 'Enter PIN => '
    pin = $stdin.gets.strip # saving pin
  end

  # requesting the tokens with the auth pin and saving it
  @access_token = request_token.get_access_token(oauth_verifier: pin)

  # defining the tokens in the config
  $config[:twitter_token] = @access_token.token
  # like that, we need to reload setup in the end, so it defines the tokens
  $config[:twitter_token_secret] = @access_token.secret

  # test whether or not i can access the api
  if @Twitter.user('dasinking').id == 78_006_580
    puts ''
    puts 'Successfully logged into Twitter!'        # although it's basically impossible to get to this step without a valid auth
    return
  end

  puts ''                                           # but i already programmed it so yeah
  puts 'somethings wrong with the auth process wtf' # all it does is requesting the user id of my profile and checking it
  puts 'that should be impossible actually'         # technically it's not even a good test, as the user id is requestable over public api
  setup                                             # so maybe i'll scrap this later on or improve it, we'll see
  # ===== twitter_auth_end =====
end

# This function sets the LastFM username
def init_new_lastfm_username
  # ===== lastfm username =====
  puts ''
  puts 'Now, enter your last.fm-username:'
  print 'Username => '
  username = $stdin.gets.strip     # get input and save into var
  $config[:lastfm_user] = username # saving username into config
  # ===== lastfm username_end =====
end

# This function sets whether a link to the tweetFM repo should be set in the
# Twitter profile.
def init_new_sourcecode_link
  # ===== source code link y/n =====
  puts
  puts 'tweetFM is free and open source, so it would be really nice of you to link the GitHub repository in your profile.'
  puts 'Do you want me to do this for you? (y/n)'

  print ''
  link = $stdin.gets.strip # saving username

  # when they type anything else than no it'll change the url #dickmove
  $config[:url] = if %w[n no nein nope nah].include?(link.downcase)
                    false
                  else
                    true
                  end
  # ===== source code link y/n_end =====
end

# This function creates the config file.
def init_new_create_config
  # ===== create the config file =====
  $config[:revision] = 1
  File.open('config.yml', 'w') do |f| # save contents of the config hash
    f.write $config.to_yaml # ... in yaml
  end
  setup # rerun setup for setting the parameters
  # ===== create the config file_end =====
end

def setup
  # check for existing config
  return init_existing if File.file?('config.yml')
  # o fuc, we need to setup
  init_new
end

# This function generates the tweet text.
def gen_tweet(artist, track, max_length: 263)
  # max_length is 263 because that's the number of chars left when including
  # the hashtag etc.
  # calculating how many chars we have left for the track name if it is too
  # long (minus 3 because "...")
  chomper = max_length - artist.length - 3
  if "#{artist}#{track}".size < max_length
    # no need to chomp anything, so return that!
    return "♫ #{artist} - #{track} #NowPlaying"
  end
  # return the chomped tweet
  "♫ #{artist} - #{track[0...chomper]}... #NowPlaying"
end

# function for creating the tweets out of a handed track
def tweet(artist, track)
  @tweetoutput = gen_tweet(artist, track)
  # lets tweet it out and print a status to the console
  @Twitter.update(@tweetoutput)
  log 'Tweet sent:', @tweetoutput.inspect
rescue StandardError => e
  # rescue when twitter is down when trying to tweet it (or some other shit)
  log 'rescued (probably twitter is down or some other shit):', e.message
  # lets maybe wait a few seconds, if it's really down
  sleep(3)
  # this rescue should be made more specific, otherwise some bad shit can happen
  loop { retry }
end

# function for getting the latest scrobbles from a profile
def scrobbleread
  # wait a second, because api rate limits and stuff. 60 calls per minute is
  # still plenty.
  sleep(1)
  # get latest scrobbles from lastfm's api
  @recent = @lastfm.user.get_recent_tracks(user: @lastfmuser, limit: 1)
rescue StandardError => e # rescue when down
  # in this case, this is good enough as it's just a GET.
  # be more careful with POST.
  log 'LastFM-API down: ' + e.message
  loop { retry }
end

# Builds a string for the log message including timestamp
def build_log(*msg)
  ["[#{Time.new.strftime('%d-%m-%Y %H:%M:%S')}]", *msg].join(' ')
end

# Prints out a message including the timestamp to the console
def log(*msg)
  puts build_log(*msg)
end

# function for tweeting out the latest track from a lastfm response
def tweet_latest_track(recent)
  # getting the scrobble date of the latest answer in UTS (unix time stamp)
  $date1 = recent.dig('date', 'uts')
  # compare it to the last saved date. this results in a tweet with every start
  # of tweetFM, but i'm fine with this
  return if $date1 == $date2
  # if the dates differ from each other, we tweet the new song
  # calling the tweet function and sending artist and track with it
  tweet(recent.dig('artist', 'content'), recent['name'])
  # and setting the new date
  $date2 = $date1
end

# ===== MAINLOOP =====
# this is where all the functions before are called. it's already pretty
# organised here, but i'm sure that i'll OOP the shit out of the rest some
# time in the future
begin
  # the setup! either create a config file, or init from a valid existing one
  setup

  # welcome online
  onlinemsg = build_log(@version, 'by @dasinking == online')
  @Twitter.update(onlinemsg)
  puts onlinemsg

  # endless loop
  loop do
    scrobbleread
    # lastfm's api answer are weird. although we only call 1, we can get 2.
    # why? because of active scrobbling.
    # when you're still actively listening to a track, it also provides you
    # with the last song you fully heard.
    # this doesn't really make sense, as we only wanted one answer, BUT WE
    # CAN ABUSE THIS, as it uses different types of answers for both of them.
    # a hash for the single answer (no active scrobble) and an array with the
    # count of two (active scrobble)
    if @recent.is_a?(Hash)
      # tweet when no scrobble is active
      tweet_latest_track(@recent)
    elsif @recent.is_a?(Array)
      # tweet when a scrobble is active
      # I use index 1, because I only want to tweet fully listened to songs
      tweet_latest_track(@recent[1])
      if $date1 == $date2
        # exception because of who the fuck knows
        # sometimes (surprisingly often) lastfm isn't down, but the api
        # answers are rubbish. enjoy the spam in your CLI.
        log 'Unsupported API-Answer'
      end
    end
  end
end
# a friend of mine once said, i should write more comments in my code. thank
# him for this clusterfuck of text everywhere: @_streamfire_ on twitter.
