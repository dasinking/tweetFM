# dHdlZXRGTSBieSBkYXNpbmtpbmcgLSBtYWRlIGluIDIwMTYgd2l0aCA8MyBD
version = "tweetFM_v3.1 by @dasinking"

require 'yaml'
require 'rubygems'
require 'json'
require 'twitter'
require 'lastfm'
require 'logger'

#config_load
@CONFIG = YAML.load_file File.expand_path '../config.yml', __FILE__
log = Logger.new('log.txt', 'daily')
log.debug (version + ' started')

#Twitter_auth
@Twitter = Twitter::REST::Client.new do |config|
  config.consumer_key    		= @CONFIG[:twitter_key]
  config.consumer_secret 		= @CONFIG[:twitter_secret]
  config.access_token        	= @CONFIG[:twitter_token]
  config.access_token_secret 	= @CONFIG[:twitter_token_secret]
end
log.debug 'Twitter logged in'

def tweet(artist, track)
		@tweetoutput = '♫ ' + artist + ' - ' + track + ' #NowPlaying'
		@Twitter.update(@tweetoutput)
		puts '[' + Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s + '] ' + 'Tweet sent: ' + @tweetoutput
	end

#Lastfm_auth
@lastfm = Lastfm.new(@CONFIG[:lastfm_apikey], @CONFIG[:lastfm_apisecret])
log.debug 'Lastfm logged in'

#MAINLOOP
@Twitter.update	('[' + Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s + '] ' + version + ' == online')
puts 			('[' + Time.new.strftime("%d-%m-%Y %H:%M:%S").to_s + '] ' + version + ' == online')
while 1 != 2 do

#SCROBBLEREAD
	begin 
		sleep(1)
		@recent = @lastfm.user.get_recent_tracks(user: @CONFIG[:lastfm_user], api_key: @lastfm_apikey, limit: 1)
		rescue => e
		log.error ('LastFM-API down')
		retry while true
	end

	# tweet if no active scrobbling
	if @recent.is_a? Hash
		$date1 = @recent["date"]["uts"]
		if $date1 != $date2
			begin
				tweet(@recent["artist"]["content"],@recent["name"])
				log.info ('Tweet sent: ♫ ' + @recent["artist"]["content"] + ' - ' + @recent["name"] + ' #NowPlaying')
				$date2 = $date1
			end
		end
	
		# tweet if active scrobbling		
		else if @recent.is_a? Array
			$date1 = @recent[1]["date"]["uts"]
			if $date1 != $date2
				tweet(@recent[1]["artist"]["content"],@recent[1]["name"])
				log.info ('Tweet sent: ♫ ' + @recent[1]["artist"]["content"] + ' - ' + @recent[1]["name"] + ' #NowPlaying')
				$date2 = $date1
			end
		# puts the exception		
		else 	
			log.warn 'Unsupported API-Answer'
		end
	end
end