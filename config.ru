# frozen_string_literal: true

require 'sinatra'
require_relative 'server.rb'

run Rack::URLMap.new('/public' => Public, '/api' => Api)
if Sinatra::Application.environment == :development || Sinatra::Application.environment == :test
  ENV['JWT_SECRET'] = "JWT_SECRET"
  ENV['JWT_ISSUER'] = "JWT_ISSUER"
end

raise 'JWT keys not found' if ENV['JWT_SECRET'].nil? || ENV['JWT_ISSUER'].nil?
if Sinatra::Application.environment == :production
  raise 'JWT is to short' if ENV['JWT_SECRET'].size < 4 || ENV['JWT_ISSUER'].size < 4
end

configure do
  set :server, :puma
  set :root, File.dirname(__FILE__)
  enable :static
  set :raise_errors, true
  set :dump_errors, false
  set :show_exceptions, false
  set :environment, ENV['RACK_ENV']
end
