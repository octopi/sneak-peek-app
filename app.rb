require 'rubygems'
require 'sinatra'
require 'mongo'
require 'uri'
require 'json'
require 'net/https'
require 'erb'
require 'foursquare2'
require 'faraday'
require 'eventmachine'
require 'em-http-request'
require 'badfruit'


MONGOHQ_URL = 'mongodb://vivek:3oEQavrg8TecPm@linus.mongohq.com:10029/app10701352'

def get_connection
  return @db_connection if @db_connection
  db = URI.parse(MONGOHQ_URL)
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end

get '/' do
	erb :index
end

post '/checkinhandler' do
	@checkin = JSON.parse(params[:checkin])
	@categories = @checkin['venue']['categories']

	puts "======= categories: #{@categories.inspect}"
	puts "======= checkin: #{params[:checkin]}"

	@categories.each { |category|
		puts category['shortName']
		if category['id'] == '4bf58dd8d48988d17f941735' or category['parents'].include? 'Movie Theaters'
			
			# call checkin response...

			# find user auth token first from DB
			db = get_connection
			users = db.collection('users')
			u = users.find({'foursquare_id' => @checkin['user']['id']})
			user_token = u.first['access_token']

			puts "user token is #{user_token}, movie is #{@checkin['event']['foreignIds']['name']}"

			delay = get_movie_runtime(@checkin['event']['foreignIds']['name'])
			puts 'DELAY FOR '+@checkin['event']['foreignIds']['name']+' IS: '+delay
			# send checkin reply
			EventMachine.run do
				puts '>>>> STARTING 15 SEC DELAY'
				EventMachine.add_timer(15) do
					puts '<<<< SENDING'
					fsq = Foursquare2::Client.new(:oauth_token => user_token)
					fsq.add_checkin_reply(@checkin['id'], {:text => 'Movie\'s over? Sneak into another one playing at '+@checkin['venue']['name'] + '!', :url => 'http://ancient-crag-6996.herokuapp.com/venue/' + @checkin['venue']['id'] + '/sneak'})

					EventMachine.stop
				end
			end
			break
		end
	}


end

get '/venue/:id/tips' do
	db = get_connection
 
	thtrs = db.collection('theaters')
	output = ''
	docs = thtrs.find({'foursquare_id'=>params[:id]})
	docs.each do |d|
		output += d['name'] + "<br />"
		d['tips'].each do |tip|
			output += tip + "<br />"
		end	
	end 

	output
end

get '/venue/:id/newtip' do
	puts 'submitting new tip'

	erb :newtip, :locals => {:id => params[:id]}
end

post '/venue/:id/newtip' do
	puts params.inspect

	db = get_connection
	thtrs = db.collection('theaters')
	thtrs.update({'foursquare_id'=>params[:id]},
			{'$push' => {'tips' => params[:tip]} })
	
	thtrs.find({}).each do |d|
		puts d.to_json
	end

	"tip posted"
end

get '/venue/:id/sneak' do
	@id = params[:id]

	fsq = Foursquare2::Client.new({:client_id => 'LJEDFWI00IQGGDZL3FKVVZEPSJDJDYDCHOSNWFNIVIVVJMRE', :client_secret => '5TVKMRWHX4XDRYVT52I1IGP3CFLPCVWMIRFWYED2P1BWBZNP'})
	venue = fsq.venue(params[:id])
	
	movie_list = []
	url = "https://api.foursquare.com/v2/venues/#{params[:id]}/events?client_id=LJEDFWI00IQGGDZL3FKVVZEPSJDJDYDCHOSNWFNIVIVVJMRE&client_secret=5TVKMRWHX4XDRYVT52I1IGP3CFLPCVWMIRFWYED2P1BWBZNP&v=20130105"
	EventMachine.run {
		http = EventMachine::HttpRequest.new(url).get
		http.errback {
			puts "fack!"
			EM.stop
		}
		http.callback {
			events = JSON.parse(http.response)
			items = events['response']['events']['items']
			items.each do |i| 
				movie_list << i['name']
			end	
			EventMachine.stop
		}
	}
	movie_list
	erb :sneak, :locals => {:movie_list => movie_list, :theater_name => venue.name}
end

# LOGIN FLOW

get '/login_redirect' do
	#shitton of work to get access_token for authorized user
	@code = params['code']

	EventMachine.run {
		# get access token from fsq given code
		token_url = 'https://foursquare.com/oauth2/access_token?client_id=LJEDFWI00IQGGDZL3FKVVZEPSJDJDYDCHOSNWFNIVIVVJMRE&client_secret=5TVKMRWHX4XDRYVT52I1IGP3CFLPCVWMIRFWYED2P1BWBZNP&grant_type=authorization_code&redirect_uri=http://ancient-crag-6996.herokuapp.com/login_redirect&code=' + @code
		puts "token_url: #{token_url}"

		http = EventMachine::HttpRequest.new(token_url).get
		http.errback {
			puts "uh oh"
			EM.stop
		}
		http.callback {
			res = JSON.parse(http.response)
			access_token = res['access_token']

			fsq = Foursquare2::Client.new(:oauth_token => access_token)
			user = fsq.user('self')

			puts "current user: #{user.id}"

			# save fsqid -> access_token mapping
			db = get_connection
			users = db.collection('users')
			users.save({'foursquare_id' => user.id, 
				'access_token' => access_token})

			EventMachine.stop
		}
	}
	"merp"
end

def get_theater_id(zipcode)
	EventMachine.run {
		http = EventMachine::HttpRequest.new("http://gateway.moviefone.com/movies/atom/closesttheaters.xml?zip=#{zipcode}").get
		http.errback {
			puts "fack!!"
			EM.stop
		}
		http.callback {
			res = Nokogiri::XML.parse(http.response)
			puts res.inspect
			puts res.children.inspect
			puts res.children.children.inspect

			EventMachine.stop
		}
	}
end

def get_movie_runtime(moviename)
	# use RT gem
	bf = BadFruit.new('5273hxpmvqqckp64c8q4uws2')
	movie = bf.movies.search_by_name(moviename)[0]
	movie.runtime
end

get '/theaters/' do
	get_theater_id('10013')
end
