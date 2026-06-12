ENV['RACK_ENV'] = 'test'
ENV['DB_PATH']  = ENV.fetch('DB_PATH', File.join(__dir__, 'tmp_test.sqlite3'))
File.delete(ENV['DB_PATH']) if File.exist?(ENV['DB_PATH'])

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
