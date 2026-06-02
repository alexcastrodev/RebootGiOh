ENV['RACK_ENV'] = 'test'
ENV['DB_HOST']  = ENV.fetch('DB_HOST', '127.0.0.1')
ENV['DB_PORT']  = ENV.fetch('DB_PORT', '3306')
ENV['DB_USER']  = ENV.fetch('DB_USER', 'bot')
ENV['DB_PASS']  = ENV.fetch('DB_PASS', 'bot')
ENV['DB_NAME']  = ENV.fetch('DB_NAME', 'botdb_test')

require 'minitest/autorun'
require 'minitest/spec'
require 'rack/test'
require 'webmock/minitest'

require_relative '../app'

module RequestHelpers
  include Rack::Test::Methods

  def app = Sinatra::Application

  def post_json(path, body)
    post path, body.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  def delete_json(path, body)
    delete path, body.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  def parsed = JSON.parse(last_response.body)
end

Minitest::Spec.include RequestHelpers
