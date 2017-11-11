# dHdlZXRGTSB2NCBieSBkYXNpbmtpbmcgLSBtYWRlIGluIDIwMTYtMTcgd2l0aCA8Mw==
@version = "tweetFM_v4-alpha2"

require 'yaml'
require 'twitter'
require 'lastfm'
require 'oauth'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE                       #only needed for some ruby installations on windows, when you get a certificate error (fuck that)

#####twitter_auth#####
@Twitter = Twitter::REST::Client.new do |config|  
  config.consumer_key       = "4iTHA7VaA85qX0gaIT6fskn9f"                             #wooooooah! api keys!
  config.consumer_secret    = "3GQIVok9vUqob30DfQlghKLM7oACHqKaJtI1YMi90LfKI7a1KT"    #those are public anyways, so it doesn't matter posting them publicly. :)
end
#####twitter_auth_end#####

#####lastfm_auth#####
@lastfm = Lastfm.new("d40320e36eca2707150f55723630436e", "aff6f8a58d4ad1a937e0128a83dec486")  #especially those, because you can't create an app on last.fm for MONTHS now. you're welcome.
#####lastfm_auth_end#####

def setup
  if File.file?("config.yml") == true then                                    #check for existing config 
    $config = {                                                               #opening the hash

    }.merge(YAML.load_file File.expand_path '../config.yml', __FILE__)        #merging the existing config to check it's contents

    if $config[:revision] != 1 then                                           #search for revision. this procedure is futureproof by increasing the number! so smart!!
      begin                                                                   #older versions of tweetFM didn't have this config entry, so it will directly identify those configs
        puts ""                                                               #those older versions use other keys and general entry names, so we want them gone.
        puts "Welcome to #{@version}! Looks like your update was successful, but we're not done yet."
        puts "Your existing configuration is based on an older installation of tweetFM."
        puts "A new configuration will be created, but before that, we need to delete the old one."
        puts "If you have any emotional connection to it, create a backup now."
        puts "When you're done, or you don't care, press enter."
        stub = $stdin.gets.strip                                              #wait for enter press
        File.delete("config.yml")                                             #delete old config
        $config = {}                                                          #zero the variable
        setup                                                                 #rerun setup for configuring the new config file
      end                                                                                      #yo dawg, i heard you like configurations
    else                                                                      #config is found which is up-to-date. it's configurations will be set
      begin
        @Twitter.access_token = $config[:twitter_token]                       #adding twitter tokens from the valid config
        @Twitter.access_token_secret = $config[:twitter_token_secret]
        @lastfmuser = $config[:lastfm_user]                                   #and the lastfm-username for parsing the latest scrobbles
        if $config[:url] == true then                                         #resetting the url in the profile with every start of tweetFM, heheheh
          @Twitter.update_profile(:url => "https://github.com/dasinking/tweetFM/")
        end
      end
    end
  else                                                                        #o fuc, we need to setup
    puts ""
    puts "Welcome, new user of tweetFM!"
    puts "Before we can start spamming you and your friends' timeline, we need to configure some things."
    puts "It won't take long!"

    $config = {}                                                              #opening the hash for incoming entries
                                                                              #it's an hash, because we'll save those settings to an external file later. it's easier like that.
    #####twitter_auth#####
      puts ""
      puts "First we need access to Twitter."
      consumer = OAuth::Consumer.new(@Twitter.consumer_key,@Twitter.consumer_secret, :site => "https://api.twitter.com")  #define where to send the request and it's parameters
      request_token = consumer.get_request_token(:oauth_callback => @callback_url)                                        #requesting and saving first oauth answer

      url = request_token.authorize_url(oauth_callback: @callback_url)                                                    #saving the auth url separately 

      puts "Open this URL in a browser: #{url}"
      pin = ''                                    #init pin variable (zeroing)
      until pin =~ /^\d+$/                        #loop for typing in the auth pin
        print "Enter PIN => "
        pin = $stdin.gets.strip                   #saving pin
      end

      @access_token = request_token.get_access_token(oauth_verifier: pin)   #requesting the tokens with the auth pin and saving it

      $config[:twitter_token] = @access_token.token                         #defining the tokens in the config
      $config[:twitter_token_secret] = @access_token.secret                 #like that, we need to reload setup in the end, so it defines the tokens

      if @Twitter.user("dasinking").id == 78006580 then                     #test whether or not i can access the api
        puts ""
        puts "Successfully logged into Twitter!"                            #although it's basically impossible to get to this step without a valid auth
      else 
        puts ""                                                             #but i already programmed it so yeah
        puts "somethings wrong with the auth process wtf"                   #all it does is requesting the user id of my profile and checking it
        puts "that should be impossible actually"                           #technically it's not even a good test, as the user id is requestable over public api
        setup                                                               #so maybe i'll scrap this later on or improve it, we'll see
      end
    #####twitter_auth_end#####

    #####lastfm username#####
      puts ""
      puts "Now, enter your last.fm-username:"
      username = ''                                     #init username variable (zeroing)
      print "Username => "
      username = $stdin.gets.strip                      #get input and save into var
      $config[:lastfm_user] = username                  #saving username into config
    #####lastfm username_end#####

    #####source code link y/n#####
      puts
      puts "tweetFM is free and open source, so it would be really nice of you to link the GitHub repository in your profile."
      puts "Do you want me to do this for you? (y/n)"
      link = ''                                     #init username variable (zeroing)

      print ""
      link = $stdin.gets.strip                      #saving username
      
      if link == "n" then                           #when they type anything else than no it'll change the url #dickmove
        $config[:url] = false  
      else
        $config[:url] = true
      end
    #####source code link y/n_end#####

    #####create the config file#####
      $config[:revision] = 1
      File.open "config.yml", 'w' do |f|              #save contents of the config hash 
        f.write $config.to_yaml                       #... in yaml
      end
      setup                                           #rerun setup for setting the parameters
    #####create the config file_end#####
  end
end

def tweet(artist, track) #function for creating the tweets out of a handed track
  if "#{artist}#{track}".size < 263 then                                                    #123 because that's the number of chars left when including the hashtag etc
    begin                                                                                   #it's just a check for the character limit
      @tweetoutput = "♫ #{artist} - #{track} #NowPlaying"                                   #this is the part of the function for tweets that fit the limit without chomping needed
      @Twitter.update(@tweetoutput)                                                         #lets tweet it out
      puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] Tweet sent: #{@tweetoutput}"   #console output and stuff
    rescue => e 
      puts "rescued (probably twitter is down or some other shit): " + e.message            #rescue when twitter is down when trying to tweet it (or some other shit)
      sleep(3)                                                                              #lets maybe wait a few seconds, if it's really down
      retry while true                                                                      #this rescue should be made more specific, otherwise some bad shit can happen
    end
  else
    begin
      artistlength = artist.size                                                            #counting the chars of the artist
      chomper = 123 - artistlength - 3                                                      #calculating how many chars we have left for the track name (minus 3 because "...")
      @tweetoutput = "♫ #{artist} - #{track[0...chomper]}... #NowPlaying"                   #chomping the trackname and put together the tweet
      @Twitter.update(@tweetoutput)                                                         #tweet that shit
      puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] Tweet sent: #{@tweetoutput}"
    rescue => e 
      puts "rescued (probably twitter is down or some other shit): " + e.message
      sleep(3)
      retry while true
    end
  end
end

def scrobbleread #function for getting the latest scrobbles from a profile
  sleep(1)                                                                    #wait a second, because api rate limits and stuff. 60 calls per minute is still plenty.
  @recent = @lastfm.user.get_recent_tracks(user: @lastfmuser, limit: 1)       #get latest scrobbles from lastfm's api
  rescue => e                                                                 #rescue when down
  puts 'LastFM-API down: ' + e.message                                        #in this case, this is good enough as it's just a GET. be more careful with POST.
  retry while true
end

#####MAINLOOP#####          #this is where all the functions before are called. it's already pretty organized here, but
begin                       #i'm sure, that i'll OOP the shit out of the rest some time in the future
  setup                   #the setup! either create a config file, or init from a valid existing one

  @Twitter.update("[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] #{@version} by @dasinking == online")  #welcome online
  puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] #{@version} by @dasinking == online"

  while 1 != 2 do         #endless loop
    begin                                                               #lastfm's api answer are weird. although we only call 1, we can get 2. why? because of active scrobbling.
      scrobbleread                                                    #when you're still actively to a track, it also provides you with the last song you fully heard.
      #tweet if no active scrobbling                                  #this doesn't really make sense, as we only wanted one answer, BUT WE CAN ABUSE THIS, as it uses different types 
      if @recent.is_a? Hash                                           #of answers for both of them. a hash for the single answer (no active scrobble) and an array for two (active)
        $date1 = @recent["date"]["uts"]                             #getting the scrobble date of the latest answer in UTS (unix time stamp)
        if $date1 != $date2                                         #comparing it to the last saved date. this results in a tweet with every start of tweetFM, but i'm fine with this
          begin                                                   #if these differ from each other, we tweet the new song
            tweet(@recent["artist"]["content"],@recent["name"]) #calling the tweet function and sending artist and track with it
            $date2 = $date1                                     #setting the new date as the new pivot element
          end
        end 
      #tweet if active scrobbling                                     #here's the if-cond for active scrobbling!
      else if @recent.is_a? Array                                     #yes, it's an array then.
        $date1 = @recent[1]["date"]["uts"]                            #same shit as above, but we need to set an index for the array 
        if $date1 != $date2                                           #i use index 1, because i only want to tweet fully listened to songs
          begin
            tweet(@recent[1]["artist"]["content"],@recent[1]["name"]) #again, same stuff as above
            $date2 = $date1
          end
        else    
          #exception because of who the fuck knows
          puts 'Unsupported API-Answer'                               #sometimes (surprisingly often) lastfm isn't down, but the api answers are rubbish. enjoy the spam in your CLI.
        end
      end
    end
  end
end

end #a friend of mine once said, i should write more comments in my code. thank him for this clusterfuck of text everywhere: @_streamfire_ on twitter.
