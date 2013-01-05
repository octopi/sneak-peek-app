require 'rubygems'
require 'sinatra'

get '/' do
	puts "HI LOGGIN"
	'sup'
end

post '/checkinhandler' do
	puts '>>> PRINTING CHECKIN'
	"params: #{params.inspect}"
end

get '/venue/:id' do
	params[:id]
end

get '/venue/:id/newtip' do
	'submitting new tip'
end