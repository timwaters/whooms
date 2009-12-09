require 'rubygems'
require 'vendor/rack/lib/rack'
require 'sinatra/sinatra/lib/sinatra'
  
set :run, false
set :environment, :production
set :views, "views"
  
require 'whooms.rb'
run Sinatra::Application

