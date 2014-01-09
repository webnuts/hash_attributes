module HashAttributes
  class DateTimeSerializer
    def self.supported_classes
      [Time, DateTime, Date]
    end

    def self.is_serializable?(object)
      supported_classes.include?(object.class)
    end

    def self.is_deserializable?(value)
      if value.is_a?(String)
        /^[0-9]{4}-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]\.[0-9]{3}Z$/.match(value) != nil
      else
        false
      end
    end

    def initialize(options)
    end

    def load(value_str)
      DateTime.parse(value_str)
    end

    def dump(value)
      value.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
    end
  end
end