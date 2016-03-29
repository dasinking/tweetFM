# tweetFM_v4 -- WIP
# contains: 
# - new scrobbleread
# - external configfile

require 'yaml'
require 'rubygems'
require 'json'
require 'twitter'
require 'lastfm'

@CONFIG = YAML.load_file File.expand_path '../config.yml', __FILE__

time = Time.new
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#Twitter_auth

@Twitter = Twitter::REST::Client.new do |config|
  config.consumer_key    = @CONFIG[:twitter_key]
  config.consumer_secret = @CONFIG[:twitter_secret]
  config.access_token        = @CONFIG[:twitter_token]
  config.access_token_secret = @CONFIG[:twitter_token_secret]
end

time = Time.new
puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Twitter logged in'

#Lastfm_auth

@lastfm = Lastfm.new(@CONFIG[:lastfm_apikey], @CONFIG[:lastfm_apisecret])

time = Time.new
puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Lastfm logged in'

#MAINLOOP


while 1 != 2 do

#SCROBBLEREAD

begin 

time = Time.new
puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Loop'
sleep(1)
@recent = @lastfm.user.get_recent_tracks(user: @CONFIG[:lastfm_user], api_key: @lastfm_apikey, limit: 1)
@recent = @recent[0] if @recent.is_a? Array

rescue => e
p e
time = Time.new
@Twitter.update('Übrigens: @lastfm ist mal wieder down. Stand: ' + time.strftime("%d.%m.%Y %H:%M:%S") + ' Uhr')
retry while true

end

begin




$date1 = @recent["date"]["uts"]

if $date1 != $date2


# Debug:
require 'pry'
binding.pry
	@artistname = @recent["artist"]["content"]	
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + '@artistname set'
	@trackname = @recent["name"]
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + '@trackname set'

	#@tweetoutput = '♫ ' + @artistname + ' - ' + @trackname + ' ' + '#NowPlaying'
	@tweetoutput = '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + '♫ ' + @artistname + ' - ' + @trackname + ' ' + '#NowPlaying'
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Waiting: ' + @tweetoutput
	@Twitter.update(@tweetoutput)
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Tweet sent: ' + @tweetoutput

	$date2 = $date1
	
	else

time = Time.new
puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'No new Scrobbles'
	
	end

else

$date1 = @recent["date"]["uts"]

if $date1 != $date2

	@artistname = @recent["artist"]["content"]
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + '@artistname set'
	@trackname = @recent["name"]
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + '@trackname set'

	#@tweetoutput = '♫ ' + @artistname + ' - ' + @trackname + ' ' + '#NowPlaying'
	@tweetoutput = '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + '♫ ' + @artistname + ' - ' + @trackname + ' ' + '#NowPlaying'
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Waiting: ' + @tweetoutput
	@Twitter.update(@tweetoutput)
	time = Time.new
	puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'Tweet sent: ' + @tweetoutput

	$dateB = $dateA

else

time = Time.new
puts '[' + time.strftime("%d-%m-%Y %H:%M:%S") + '] ' + 'No new Scrobbles'

end

end

end

