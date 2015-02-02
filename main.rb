require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'live_life_abroad' 


get "/name" do
  "my name is Timothe Beiko"
end

get "/template" do
  erb :profile
end