require 'rubygems'
require 'bundler'
require 'newrelic_rpm'
require 'sinatra/multi_route'

Bundler.require

require './myapp'
run Sinatra::Application
