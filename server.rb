require 'sinatra'
require 'json'
require_relative './lib/aggregator'
require_relative './lib/reading'

GlobalState = {}

helpers do
  def devices
    GlobalState[:devices] ||= {}
  end
end

# Gets the aggregator for a device, creating it if it doesn't exist.
#
# @param [String] device_id the ID of the device
# @return [Aggregator] the aggregator for the device
def aggregator_for(device_id)
  raise ArgumentError, 'device_id is required' unless device_id
  raise ArgumentError, '"reading" is not a valid device ID' if device_id == 'reading' # TODO this is a hack to prevent a conflict with the /reading endpoint

  devices[device_id] ||= Aggregator.new(device_id)
end

get '/hello' do
  'Hello, World!'
end

# Adds readings to the aggregator for a device.
#
# @param [String] id the ID of the device
# @param [Array] readings an array of readings
# @param [DateTime] readings.timestamp the timestamp of the reading
# @param [Integer] readings.count the count of the reading
post '/readings' do
  data = JSON.parse(request.body.read)
  
  device_id = data['id']
  readings = data['readings'] || []

  raise ArgumentError, 'readings must be an array' unless readings.is_a?(Array)

  readings.each do |reading|
    timestamp = DateTime.parse(reading['timestamp'])
    count = reading['count']

    raise ArgumentError, 'timestamp must be a DateTime' unless timestamp.is_a?(DateTime)
    raise ArgumentError, 'count must be an Integer' unless count.is_a?(Integer)

    reading = Reading.new(timestamp, count)
    aggregator_for(device_id).add_reading(reading)
  end

  status 200
  {status: 'ok'}.to_json
end

# Gets the latest timestamp for a device.
#
# @param [String] device_id the ID of the device
get '/:device_id/latest' do
  reading = aggregator_for(params[:device_id]).latest_reading

  if reading.nil?
    status 404
    return {status: 'error', message: 'No readings found'}.to_json
  end

  status 200
  {latest_timestamp: reading.timestamp}.to_json
end

# Gets the cumulative count for a device.
#
# @param [String] device_id the ID of the device
get '/:device_id/cumulative_count' do
  aggregator = aggregator_for(params[:device_id])

  status 200
  {cumulative_count: aggregator.cumulative_count}.to_json
end

# Global error handling
set :show_exceptions, false

error ArgumentError, JSON::ParserError do
  halt 400, {status: 'error', message: env['sinatra.error'].message}.to_json
end

error do
  halt 500, {status: 'error', message: env['sinatra.error'].message}.to_json
end