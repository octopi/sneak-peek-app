require 'rubygems'
require 'sinatra'

get '/' do
	puts "HI LOGGIN"
	'sup'
end

post '/checkinhandler' do
	puts '>>> PRINTING CHECKIN'
	'end of checkin handler'
end

get '/venue/:id' do
	params[:id]
end

get '/venue/:id/newtip' do
	'submitting new tip'
end