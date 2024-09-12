require 'date'
require_relative 'reading'

# An aggregator for readings from a device that... um, reads things I guess.
#  
class Aggregator
  attr_reader :readings_by_timestamp
  attr_reader :cumulative_count
  attr_reader :device_id

  def initialize(device_id)
    @device_id = device_id
    @readings_by_timestamp = {}
    @latest_timestamp = nil
    @cumulative_count = 0
  end

  # Logs a message with the current time and the device ID.
  def log(msg)
    puts "#{Time.now} - #{device_id} - #{msg}"
  end

  # Adds a reading to the aggregator.  If this reading is more recent than the latest reading, it will become the latest reading.  
  # If a reading with the same timestamp is already in the aggregator, it will be ignored.
  # If it is older, it will be added to the list but the latest reading will not change.
  #
  # @param [Reading] reading the reading to add
  def add_reading(reading)
    raise ArgumentError, 'reading must be a Reading' unless reading.is_a?(Reading)

    if @readings_by_timestamp.key?(reading.timestamp)
      log("Ignoring reading with existing timestamp #{reading.timestamp.iso8601}")
      return
    end

    @readings_by_timestamp[reading.timestamp] = reading
    @cumulative_count += reading.count

    log("Added reading with timestamp #{reading.timestamp.iso8601} and count #{reading.count}")

    # Set latest timestamp if needed
    if @latest_timestamp.nil? || reading.timestamp > @latest_timestamp
      log("Updating latest timestamp to #{reading.timestamp.iso8601}")
      @latest_timestamp = reading.timestamp
    end
  end

  # Gets the latest reading.  Will be nil if no readings have been added.
  # 
  # @return [Reading] the latest reading
  def latest_reading
    @readings_by_timestamp[@latest_timestamp]
  end
end