require_relative 'test_helper'

describe 'GET /invoke/:discord_user_id/:node_name/:card_id' do
  let(:node_host) { 'http://node.example.com' }

  before do
    Node.delete_all
    Node.create!(discord_user_id: '111', name: 'main', host: node_host)
  end

  describe 'happy path' do
    before do
      stub_request(:get, "#{node_host}/deck/exodia")
        .to_return(status: 200,
                   body: { card_url: 'https://cdn.example.com/exodia.jpg' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      get '/invoke/111/main/exodia'
    end

    it 'returns 200' do
      _(last_response.status).must_equal 200
    end

    it 'returns the card_url' do
      _(parsed['card_url']).must_equal 'https://cdn.example.com/exodia.jpg'
    end
  end

  describe 'node ownership' do
    it 'returns 404 for an unknown discord_user_id' do
      get '/invoke/999/main/exodia'
      _(last_response.status).must_equal 404
      _(parsed['error']).must_equal 'node not found'
    end

    it 'returns 404 when the node name does not belong to the user' do
      get '/invoke/111/ghost/exodia'
      _(last_response.status).must_equal 404
    end

    it 'does not allow user 222 to invoke user 111 node' do
      get '/invoke/222/main/exodia'
      _(last_response.status).must_equal 404
    end
  end

  describe 'invalid card_url in node response' do
    it 'returns 422 when card_url is missing' do
      stub_request(:get, "#{node_host}/deck/exodia")
        .to_return(status: 200, body: { other: 'data' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 422
      _(parsed['error']).must_equal 'missing card_url in node response'
    end

    it 'returns 422 when card_url is not an image' do
      stub_request(:get, "#{node_host}/deck/exodia")
        .to_return(status: 200, body: { card_url: 'https://cdn.example.com/exodia.pdf' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 422
      _(parsed['error']).must_equal 'card_url is not a valid image URL'
    end

    it 'returns 422 when card_url is a relative path' do
      stub_request(:get, "#{node_host}/deck/exodia")
        .to_return(status: 200, body: { card_url: '/images/exodia.jpg' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 422
      _(parsed['error']).must_equal 'card_url is not a valid image URL'
    end

    it 'returns 422 when card_url is an empty string' do
      stub_request(:get, "#{node_host}/deck/exodia")
        .to_return(status: 200, body: { card_url: '' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 422
    end
  end

  describe 'node communication failures' do
    it 'returns 502 when the node returns a non-2xx status' do
      stub_request(:get, "#{node_host}/deck/exodia").to_return(status: 500)
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 502
    end

    it 'returns 502 when the node is unreachable' do
      stub_request(:get, "#{node_host}/deck/exodia").to_raise(Errno::ECONNREFUSED)
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 502
      _(parsed['error']).must_include 'could not reach node'
    end

    it 'returns 502 when the node times out' do
      stub_request(:get, "#{node_host}/deck/exodia").to_raise(Net::ReadTimeout)
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 502
      _(parsed['error']).must_include 'could not reach node'
    end

    it 'returns 502 when the node returns invalid JSON' do
      stub_request(:get, "#{node_host}/deck/exodia")
        .to_return(status: 200, body: 'not json',
                   headers: { 'Content-Type' => 'application/json' })
      get '/invoke/111/main/exodia'
      _(last_response.status).must_equal 502
      _(parsed['error']).must_equal 'node response is not valid JSON'
    end
  end

  describe 'supported image formats' do
    %w[jpg jpeg png gif webp avif].each do |ext|
      it "accepts .#{ext}" do
        stub_request(:get, "#{node_host}/deck/exodia")
          .to_return(status: 200,
                     body: { card_url: "https://cdn.example.com/exodia.#{ext}" }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        get '/invoke/111/main/exodia'
        _(last_response.status).must_equal 200
      end
    end
  end
end
