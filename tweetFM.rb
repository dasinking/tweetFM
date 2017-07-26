# dHdlZXRGTSB2NCBieSBkYXNpbmtpbmcgLSBtYWRlIGluIDIwMTYtMTcgd2l0aCA8Mw==
@version = "tweetFM_v4-alpha2"
require 'yaml'
require 'rubygems'
require 'twitter'
require 'lastfm'
require 'oauth'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE                       #only needed for some ruby installations on windows, when you get a certificate error (fuck that)

#####twitter_auth#####
  @Twitter = Twitter::REST::Client.new do |config|
    config.consumer_key       = "4iTHA7VaA85qX0gaIT6fskn9f"
    config.consumer_secret    = "3GQIVok9vUqob30DfQlghKLM7oACHqKaJtI1YMi90LfKI7a1KT"
  end
#####twitter_auth_end#####

#####lastfm_auth#####
  @lastfm = Lastfm.new("d40320e36eca2707150f55723630436e", "aff6f8a58d4ad1a937e0128a83dec486")
#####lastfm_auth_end#####

def setup
  if File.file?("config.yml") == true then                                  #check for existing config 
    $config = {

    }.merge(YAML.load_file File.expand_path '../config.yml', __FILE__)      #it's already there? yay. no setup required.

    if $config[:revision] != 1 then                                         #search for revision. this procedure is futureproof by increasing the number! so smart!!
      begin
        puts ""
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
    else                                                                      #up-to-date config is found and configurations will be set
      begin
        @Twitter.access_token = $config[:twitter_token]
        @Twitter.access_token_secret = $config[:twitter_token_secret]
        @lastfmuser = $config[:lastfm_user]
        if $config[:url] == true then                                         #resetting the url with every start of tweetFM, heheheh
          @Twitter.update_profile(:url => "https://github.com/dasinking/tweetFM/")
        end
      end
    end
  else                                                                        #o fuc
    puts ""
    puts "Welcome, new user of tweetFM!"
    puts "Before we can start spamming you and your friends' timeline, we need to configure some things."
    puts "It won't take long!"

    $config = {}

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
        puts "Successfully logged into Twitter!"
      else 
        puts ""
        puts "somethings wrong with the auth process wtf"
        puts "that should be impossible actually"
        auth
      end
    #####twitter_auth_end#####

    #####lastfm username#####
      puts ""
      puts "Now, enter your last.fm-username:"
      username = ''                                     #init username variable (zeroing)
      print "Username => "
      username = $stdin.gets.strip                      #saving username
      $config[:lastfm_user] = username
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

def tweet(artist, track)
  if "#{artist}#{track}".size < 123 then
    begin
      @tweetoutput = "♫ #{artist} - #{track} #NowPlaying"
      @Twitter.update(@tweetoutput)
      puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] Tweet sent: #{@tweetoutput}"
    rescue => e 
      puts "rescued (probably twitter is down other some shit): " + e.message
      sleep(3)
      retry while true
    end
  else
    begin
      artistlength = artist.size
      chomper = 123 - artistlength - 3
      @tweetoutput = "♫ #{artist} - #{track[0...chomper]}... #NowPlaying"
      @Twitter.update(@tweetoutput)
      puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] Tweet sent: #{@tweetoutput}"      
    rescue => e 
      puts "rescued (probably twitter is down other some shit): " + e.message
      sleep(3)
      retry while true
    end
  end
end

def scrobbleread
  sleep(1)
  @recent = @lastfm.user.get_recent_tracks(user: @lastfmuser, limit: 1)      #get latest scrobbles from lastfm's api
  rescue => e                                                                #rescue when down
  puts 'LastFM-API down: ' + e.message
  retry while true
end

#MAINLOOP
begin
    setup

    @Twitter.update("[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] #{@version} by @dasinking == online")  #welcome online
    puts "[#{Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s}] #{@version} by @dasinking == online"

    while 1 != 2 do
        begin           
            scrobbleread
            #tweet if no active scrobbling
            if @recent.is_a? Hash
                $date1 = @recent["date"]["uts"]
                if $date1 != $date2
                    begin
                        tweet(@recent["artist"]["content"],@recent["name"])
                        $date2 = $date1
                    end
                end 
            #tweet if active scrobbling     
            else if @recent.is_a? Array
              $date1 = @recent[1]["date"]["uts"]
              if $date1 != $date2
                begin
                  tweet(@recent[1]["artist"]["content"],@recent[1]["name"])
                  $date2 = $date1
                end     
              else    
                #exception because of who the fuck knows
                puts 'Unsupported API-Answer'
              end
            end
        end
    end
end
end