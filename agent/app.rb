require 'sinatra'
require 'sinatra/json'
require 'json'
require 'net/http'
require 'uri'

require_relative 'extensions/string'
require_relative 'db/connection'
require_relative 'models/node'
require_relative 'logger'

configure do
  set :bind, '0.0.0.0'
  set :port, ENV.fetch('PORT', 4567)
  set :show_exceptions, false

  set :host_authorization, permitted_hosts: []

  retries = 0
  begin
    ActiveRecord::MigrationContext.new(
      File.join(__dir__, 'db/migrations')
    ).migrate
  rescue ActiveRecord::DatabaseConnectionError, Mysql2::Error::ConnectionError => e
    retries += 1
    raise if retries > 10
    $stderr.puts "DB not ready (attempt #{retries}/10): #{e.message}"
    sleep 3
    retry
  end
end

error do
  json error: env['sinatra.error'].message
end

# POST /register
# Body: { "host": "http://1.2.3.4:8080", "discord_user_id": "123456789" }
post '/register' do
  payload         = JSON.parse(request.body.read) rescue {}
  host            = payload['host']&.strip&.strip_trailing_slash
  discord_user_id = payload['discord_user_id']&.strip

  halt 400, json(error: 'host is required')            if host.nil? || host.empty?
  halt 400, json(error: 'discord_user_id is required') if discord_user_id.nil? || discord_user_id.empty?

  name = discord_user_id

  halt 409, json(error: 'user already has a node — revoke it first') if Node.exists?(discord_user_id: discord_user_id)

  node           = Node.new(discord_user_id: discord_user_id, name: name, host: host, last_seen: Time.now)
  node.save!

  status 201
  json discord_user_id: node.discord_user_id, name: node.name, host: node.host
end

# DELETE /revoke
# Body: { "discord_user_id": "123456789" }
delete '/revoke' do
  payload         = JSON.parse(request.body.read) rescue {}
  discord_user_id = payload['discord_user_id']&.strip

  halt 400, json(error: 'discord_user_id is required') if discord_user_id.nil? || discord_user_id.empty?

  node = Node.find_by(discord_user_id: discord_user_id)
  halt 404, json(error: 'node not found') unless node

  node.destroy!

  status 200
  json message: 'node revoked'
end

VALID_IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .avif].freeze

def valid_image_url?(url)
  return false unless url.is_a?(String) && url =~ /\Ahttps?:\/\//i
  ext = File.extname(URI.parse(url).path).downcase rescue ''
  VALID_IMAGE_EXTENSIONS.include?(ext)
end

# GET /invoke/:discord_user_id/:card_id
# Finds the node owned by discord_user_id, calls {host}/deck/:card_id
get '/invoke/:discord_user_id/:card_id' do
  node = Node.find_by(discord_user_id: params[:discord_user_id])
  halt 404, json(error: 'node not found') unless node

  target = URI.parse("#{node.host.strip_trailing_slash}/deck/#{params[:card_id]}")

  begin
    res = Net::HTTP.start(target.host, target.port,
                          use_ssl: target.scheme == 'https',
                          open_timeout: 5,
                          read_timeout: 15) { |h| h.get(target.request_uri) }
    unless res.is_a?(Net::HTTPSuccess)
      AppLogger.error("[invoke] node returned #{res.code}: #{res.body.to_s[0, 200]}")
      halt 502, json(error: "node returned #{res.code}")
    end

    data     = JSON.parse(res.body)
    card_url = data['card_url']

    halt 422, json(error: 'missing card_url in node response')      if card_url.nil?
    halt 422, json(error: 'card_url is not a valid image URL') unless valid_image_url?(card_url)

    json card_url: card_url
  rescue JSON::ParserError
    status 502
    json error: 'node response is not valid JSON'
  rescue => e
    status 502
    json error: "could not reach node: #{e.message}"
  end
end

# GET /search/:discord_user_id?q=<query>
# Proxies to node's GET /deck?search=<query> and returns autocomplete suggestions
get '/search/:discord_user_id' do
  node = Node.find_by(discord_user_id: params[:discord_user_id])
  halt 404, json(error: 'node not found') unless node

  q      = params[:q].to_s.strip
  target = URI.parse("#{node.host.strip_trailing_slash}/deck?search=#{URI.encode_uri_component(q)}")

  begin
    res = Net::HTTP.start(target.host, target.port,
                          use_ssl: target.scheme == 'https',
                          open_timeout: 5,
                          read_timeout: 10) { |h| h.get(target.request_uri) }
    halt 502, json(error: "node returned #{res.code}") unless res.is_a?(Net::HTTPSuccess)

    data  = JSON.parse(res.body)
    cards = (data || []).map { |c| { name: c['identifier'], value: c['identifier'] } }
    json cards: cards
  rescue JSON::ParserError
    status 502
    json error: 'node response is not valid JSON'
  rescue => e
    status 502
    json error: "could not reach node: #{e.message}"
  end
end

# GET /trap
get '/trap' do
  send_file File.join(__dir__, 'assets', 'hide.jpg'), type: 'image/jpeg'
end
