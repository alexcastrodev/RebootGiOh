require_relative 'test_helper'

describe 'DELETE /revoke' do
  before { Node.delete_all }

  describe 'revoking an existing node' do
    before do
      Node.create!(discord_user_id: '111', name: '111', host: 'http://1.2.3.4:8080')
      delete_json '/revoke', discord_user_id: '111'
    end

    it 'returns 200' do
      _(last_response.status).must_equal 200
    end

    it 'returns confirmation message' do
      _(parsed['message']).must_equal 'node revoked'
    end

    it 'removes the node' do
      _(Node.count).must_equal 0
    end

    it 'allows re-registering after revoke' do
      post_json '/register', host: 'http://5.5.5.5:8080', discord_user_id: '111'
      _(last_response.status).must_equal 201
    end
  end

  describe 'revoking a non-existent node' do
    before { delete_json '/revoke', discord_user_id: '999' }

    it 'returns 404' do
      _(last_response.status).must_equal 404
    end

    it 'returns error message' do
      _(parsed['error']).must_equal 'node not found'
    end
  end

  describe 'missing discord_user_id' do
    before { delete_json '/revoke', {} }

    it 'returns 400' do
      _(last_response.status).must_equal 400
    end

    it 'returns error message' do
      _(parsed['error']).must_equal 'discord_user_id is required'
    end
  end
end
