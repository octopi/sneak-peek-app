require 'rubygems'
require 'sinatra'

get '/' do
	puts "HI LOGGIN"
	'sup'
end

post '/checkinhandler' do
	@venue = params[:checkin]['venue']
	@checkinparam = params[:checkin]
	

	puts "venue: #{@venue.inspect}"
	puts '>>> VENUE CATEORIES'
	puts @venue['categories']
end

get '/venue/:id' do
	params[:id]
end

get '/venue/:id/newtip' do
	'submitting new tip'
end