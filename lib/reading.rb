require 'date'

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
end