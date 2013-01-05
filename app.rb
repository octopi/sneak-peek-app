require 'rubygems'
require 'sinatra'
require 'mongo'
require 'uri'
require 'json'

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

	puts "venue: #{@categories.inspect}"
	puts '>>> VENUE CATEORIES'
	puts @venue['categories']
end

get '/venue/:id' do
	db = get_connection
 
	puts "Collections"
	puts "==========="
	collections = db.collection_names
	puts collections

	thtrs = db.collection('theaters')
	puts thtrs

	output = ''
	docs = thtrs.find({'foursquare_id'=>'-1'})
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
