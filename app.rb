require 'rubygems'
require 'sinatra'
require 'mongo'
require 'uri'
require 'json'
require 'net/https'

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
	puts "HI LOGGIN"
	'sup'
end

post '/checkinhandler' do
	@checkin = JSON.parse(params[:checkin])
	@categories = @checkin['venue']['categories']

	puts "categories: #{@categories.inspect}"

	@categories.each { |category|
		puts category['shortName']
		if category['id'] == '4bf58dd8d48988d17f941735'
			puts 'ITS A MOVIE THEATER'
		end
	}
	
	puts '>>> VENUE CATEORIES'
end

get '/venue/:id' do
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
	'submitting new tip'
end

post '/venue/:id/newtip' do
end

# LOGIN FLOW
get '/login_redirect' do
	@code = params['code']
	@uri = URI.parse("https://foursquare.com/oauth2/access_token?client_id=LJEDFWI00IQGGDZL3FKVVZEPSJDJDYDCHOSNWFNIVIVVJMRE&client_secret=5TVKMRWHX4XDRYVT52I1IGP3CFLPCVWMIRFWYED2P1BWBZNP&grant_type=authorization_code&redirect_uri=http://ancient-crag-6996.herokuapp.com/login_redirect&code=" + @code)
	@http = Net::HTTP.new(@uri.host, @uri.port)
	@http.use_ssl = true
	@http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	@request = Net::HTTP::Get.new(uri.request_uri)

	@response = @http.request(@request)
	puts "response body: #{@response.body}"

	# TODO: save user and auth code
end
