require 'rubygems'
require 'bundler'

Bundler.require

require './myapp'
run Sinatra::Application
