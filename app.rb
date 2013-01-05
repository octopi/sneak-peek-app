require 'rubygems'
require 'sinatra'

get '/' do
	puts 'something here'
	'sup'
end

post '/checkinhandler' do
	'end of checkin handler'
end

get '/venue/:id' do
	params[:id]
end

get '/venue/:id/newtip' do
	'submitting new tip'
end