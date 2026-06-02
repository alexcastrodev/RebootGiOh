require_relative 'test_helper'

describe 'POST /register' do
  before { Node.delete_all }

  describe 'registering a new node' do
    before { post_json '/register', host: 'http://1.2.3.4:8080', discord_user_id: '111', name: 'main' }

    it 'returns 201' do
      _(last_response.status).must_equal 201
    end

    it 'returns discord_user_id, name, and host' do
      _(parsed.slice('discord_user_id', 'name', 'host')).must_equal(
        'discord_user_id' => '111',
        'name'            => 'main',
        'host'            => 'http://1.2.3.4:8080'
      )
    end

    it 'persists exactly one node' do
      _(Node.count).must_equal 1
    end
  end

  describe 'same user registering a second node without revoking first' do
    before do
      post_json '/register', host: 'http://1.1.1.1:8080', discord_user_id: '111', name: 'main'
      post_json '/register', host: 'http://2.2.2.2:8080', discord_user_id: '111', name: 'backup'
    end

    it 'returns 409' do
      _(last_response.status).must_equal 409
    end

    it 'keeps only the original node' do
      _(Node.count).must_equal 1
    end

    it 'returns an error message' do
      _(parsed['error']).must_equal 'user already has a node — revoke it first'
    end
  end

  describe 'two different users registering the same node name' do
    before do
      post_json '/register', host: 'http://1.1.1.1:8080', discord_user_id: '111', name: 'main'
      post_json '/register', host: 'http://2.2.2.2:8080', discord_user_id: '222', name: 'main'
    end

    it 'creates two separate nodes' do
      _(Node.count).must_equal 2
    end
  end

  describe 'missing fields' do
    it 'returns 400 when host is missing' do
      post_json '/register', discord_user_id: '111', name: 'main'
      _(last_response.status).must_equal 400
      _(parsed['error']).must_equal 'host is required'
    end

    it 'returns 400 when host is blank' do
      post_json '/register', host: '   ', discord_user_id: '111', name: 'main'
      _(last_response.status).must_equal 400
      _(parsed['error']).must_equal 'host is required'
    end

    it 'returns 400 when discord_user_id is missing' do
      post_json '/register', host: 'http://1.2.3.4:8080', name: 'main'
      _(last_response.status).must_equal 400
      _(parsed['error']).must_equal 'discord_user_id is required'
    end

    it 'returns 400 when name is missing' do
      post_json '/register', host: 'http://1.2.3.4:8080', discord_user_id: '111'
      _(last_response.status).must_equal 400
      _(parsed['error']).must_equal 'name is required'
    end

    it 'returns 400 when body is not JSON' do
      post '/register', 'not json', 'CONTENT_TYPE' => 'application/json'
      _(last_response.status).must_equal 400
    end
  end
end
