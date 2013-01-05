require 'rubygems'
require 'sinatra'

get '/' do
	'sup'
end

post '/checkinhandler' do
	'checkin'
end

get '/venue/:id' do
	params[:id]
end

get '/venue/:id/newtip' do
	'submitting new tip'
end