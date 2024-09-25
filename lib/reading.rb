require 'date'
require 'json'

class Reading
  attr :timestamp
  attr :count
  
  # Creates a new reading.
  #
  # @param [DateTime] timestamp the timestamp of the reading
  # @param [Integer] count the count of the reading
  def initialize(timestamp, count)
    raise ArgumentError, 'timestamp must be a DateTime' unless timestamp.is_a?(DateTime)
    raise ArgumentError, 'count must be an Integer' unless count.is_a?(Integer)

    @timestamp = timestamp
    @count = count
  end

  def as_json
    {timestamp: @timestamp&.iso8601, count: @count}
  end

  def to_json
    as_json.to_json
  end

  # json param is a hash
  def self.from_json(json)
    Reading.new(DateTime.parse(json['timestamp']), json['count'])
  end

end