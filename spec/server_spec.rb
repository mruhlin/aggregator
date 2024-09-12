require 'rack/test'
require_relative '../server'
require 'securerandom'

describe 'Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:device_id) { SecureRandom.uuid }

  it 'responds to /hello' do
    get '/hello'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello, World!')
  end

  # Helper method to post JSON data
  def json_post(path, data)
    post path, data.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  describe 'POST /readings' do
    it 'adds a reading to the aggregator' do
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00', count: 3}]}
      expect(last_response.status).to eq(200)
    end

    it 'ignores an existing timestamp' do
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00', count: 3}]}
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00', count: 4}]}
      expect(last_response.status).to eq(200)

      get "/#{device_id}/cumulative_count"
      expect(last_response.body).to eq({cumulative_count: 3}.to_json)
    end

    it 'ignores an existing timestamp from a different time zone' do
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00Z', count: 3}]}
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T01:00:00+01:00', count: 4}]}
      expect(last_response.status).to eq(200)

      get "/#{device_id}/cumulative_count"
      expect(last_response.body).to eq({cumulative_count: 3}.to_json)
    end

    it 'returns an error if readings is not an array' do
      json_post '/readings', {id: device_id, readings: 'not an array'}
      puts last_response.body
      expect(last_response.status).to eq(400)
    end

    it 'returns an error if timestamp is not a DateTime' do
      json_post '/readings', {id: device_id, readings: [{timestamp: 'not a timestamp', count: 3}]}
      expect(last_response.status).to eq(400)
    end

    it 'returns an error if count is not an Integer' do
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00', count: 'not an integer'}]}
      expect(last_response.status).to eq(400)
    end
  end

  describe 'GET /:device_id/latest' do
    it 'returns the latest timestamp for a device' do
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00', count: 3}]}
      get "/#{device_id}/latest"
      expect(last_response.body).to eq({latest_timestamp: '2024-01-01T00:00:00+00:00'}.to_json)
    end

    it 'returns an error if no readings are found' do
      get "/#{device_id}/latest"
      expect(last_response.status).to eq(404)
    end
  end

  describe 'GET /:device_id/cumulative_count' do
    it 'returns the cumulative count for a device' do
      json_post '/readings', {id: device_id, readings: [{timestamp: '2024-01-01T00:00:00', count: 3}]}

      get "/#{device_id}/cumulative_count"
      expect(last_response.body).to eq({cumulative_count: 3}.to_json)
    end

    it 'returns 0 if no readings are found' do
      get "/#{device_id}/cumulative_count"
      expect(last_response.body).to eq({cumulative_count: 0}.to_json)
    end
  end
end