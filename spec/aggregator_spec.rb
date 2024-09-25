require 'spec_helper'
require 'aggregator'
require 'date'

describe Aggregator do
  let(:aggregator) { Aggregator.new('test_device') }

  describe '#add_reading' do
    it 'adds a reading to the aggregator' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)

      expect(aggregator.latest_reading).to eq(reading)
      expect(aggregator.readings_by_timestamp[timestamp]).to eq(reading)
      expect(aggregator.readings_by_timestamp.count).to eq(1)
    end

    it 'updates the latest timestamp when a newer reading is added' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)

      new_timestamp = DateTime.new(2024, 1, 1, 0, 1, 0)
      new_reading = Reading.new(new_timestamp, 4)
      aggregator.add_reading(new_reading)

      expect(aggregator.latest_reading).to eq(new_reading)
      expect(aggregator.readings_by_timestamp[new_timestamp]).to eq(new_reading)
      expect(aggregator.readings_by_timestamp.count).to eq(2)
    end

    it 'does not update the latest timestamp when an older reading is added' do
      timestamp = DateTime.new(2024, 1, 1, 0, 1, 0)
      reading = Reading.new(timestamp, 4)
      aggregator.add_reading(reading)

      old_timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      old_reading = Reading.new(old_timestamp, 3)
      aggregator.add_reading(old_reading)

      expect(aggregator.latest_reading).to eq(reading)
      expect(aggregator.readings_by_timestamp[timestamp]).to eq(reading)
      expect(aggregator.readings_by_timestamp[old_timestamp]).to eq(old_reading)
      expect(aggregator.readings_by_timestamp.count).to eq(2)
    end

    it 'does not add a reading with the same timestamp' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)

      new_reading = Reading.new(timestamp, 4)
      aggregator.add_reading(new_reading)

      expect(aggregator.cumulative_count).to eq(3)
      expect(aggregator.readings_by_timestamp.count).to eq(1)
    end

    it 'raises an error if the argument is not a Reading' do
      expect { aggregator.add_reading('not a reading') }.to raise_error(ArgumentError)
    end
  end

  describe '#as_json' do
    it 'returns the aggregator as a json hash' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)

      json = aggregator.as_json
      expect(json[:device_id]).to eq('test_device')
      expect(json[:cumulative_count]).to eq(3)
      expect(json[:latest_timestamp]).to eq(timestamp)
      expect(json[:readings_by_timestamp].count).to eq(1)

      expect(json[:readings_by_timestamp][timestamp.iso8601][:timestamp]).to eq(timestamp.iso8601)
      expect(json[:readings_by_timestamp][timestamp.iso8601][:count]).to eq(3)
    end
  end

  describe '#from_json' do
    it 'creates an aggregator from a json hash' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)

      json = aggregator.to_json
      new_aggregator = Aggregator.from_json(JSON.parse(json))

      expect(new_aggregator.device_id).to eq('test_device')
      expect(new_aggregator.cumulative_count).to eq(3)
      expect(new_aggregator.latest_timestamp).to eq(timestamp)
      expect(new_aggregator.readings_by_timestamp.count).to eq(1)

      expect(new_aggregator.readings_by_timestamp[timestamp].count).to match(reading.count)
    end
  end

  describe '#save!' do
    it 'saves to disk' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)

      aggregator.save!
      expect(File).to exist('test_device.json')

      json = JSON.parse(File.read('./data/test_device.json'))
      expect(json['device_id']).to eq('test_device')
    end
  end

  describe '.load' do
    it 'loads from disk' do
      timestamp = DateTime.new(2024, 1, 1, 0, 0, 0)
      reading = Reading.new(timestamp, 3)
      aggregator.add_reading(reading)
      aggregator.save!

      new_aggregator = Aggregator.load('test_device')
      expect(new_aggregator.device_id).to eq('test_device')
      expect(new_aggregator.cumulative_count).to eq(3)
      expect(new_aggregator.latest_timestamp).to eq(timestamp)
      expect(new_aggregator.readings_by_timestamp.count).to eq(1)

      expect(new_aggregator.readings_by_timestamp[timestamp].count).to match(reading.count)
    end
  end

end