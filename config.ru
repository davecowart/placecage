require 'rubygems'
require 'bundler'
require 'newrelic_rpm'

Bundler.require

require './myapp'
run Sinatra::Application
