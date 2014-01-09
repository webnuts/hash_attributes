module HashAttributes
  extend ActiveSupport::Concern

  included do
    self.register_value_serializer("HashAttributes::DateTimeSerializer")
  end

  def initialize(*args, &block)
    if args[0].is_a?(Hash)
      args[0] = args[0].with_indifferent_access
      args[0] = args[0].inject(HashWithIndifferentAccess.new(self.class.hash_column => {})) do |result, (attribute_name, value)|
        if self.class.hash_column == attribute_name
          result[self.class.hash_column].merge!(value)
        elsif self.class.column_names.include?(attribute_name)
          result[attribute_name] = value
        else
          result[self.class.hash_column][attribute_name] = value
        end
        result
      end
    end

    if block_given?
      super(*args) do |new_record|
        yield new_record if block_given?
      end
    else
      super(*args)
    end
  end

  def is_valid_hash_column_attribute_name?(attribute_name)
    attribute_name = attribute_name.to_s
    self.class.column_names.include?(attribute_name) == false && self.class.is_valid_attribute_name?(attribute_name)
  end

  # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/attribute_methods/read.rb
  # http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Read.html#method-i-read_attribute
  # prefix: "", suffix: ""
  def read_attribute(attribute_name)
    attribute_name = attribute_name.to_s
    if attribute_name == self.class.hash_column
      (super(attribute_name) || {}).with_indifferent_access
    elsif is_valid_hash_column_attribute_name?(attribute_name)
      read_hash_column_attribute(attribute_name)
    else
      super(attribute_name)
    end
  end

  def read_hash_column_attribute(attribute_name)
    self.class.deserialize_hash_column_attribute(attribute_name, read_attribute(self.class.hash_column).try(:[], attribute_name))
  end

  # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/attribute_methods/write.rb
  # http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Write.html
  # prefix: "", suffix: "="
  def write_attribute(attribute_name, value)
    attribute_name = attribute_name.to_s
    if attribute_name == self.class.hash_column
      value = value.try(:with_indifferent_access)
      unless read_attribute(self.class.hash_column).try(:with_indifferent_access) == value
        attribute_will_change!(attribute_name)
      end
      super(self.class.hash_column, self.class.serialize_hash_column_attribute(self.class.hash_column, value))
      value
    elsif is_valid_hash_column_attribute_name?(attribute_name)
      write_hash_column_attribute(attribute_name, value)
    else
      super(attribute_name, value)
    end
  end

  def write_hash_column_attribute(attribute_name, value)
    if value != read_attribute(attribute_name)
      verify_readonly_attribute(attribute_name)
      attribute_will_change!(attribute_name)
      write_attribute(self.class.hash_column, read_attribute(self.class.hash_column).merge(attribute_name => value))
    end
    value
  end

  # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/attribute_methods/before_type_cast.rb
  # http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/BeforeTypeCast.html
  # prefix: "", suffix: "_before_type_cast"
  def read_attribute_before_type_cast(attribute_name)
    if is_valid_hash_column_attribute_name?(attribute_name)
      read_hash_column_attribute(attribute_name)
    else
      super(attribute_name)
    end
  end

  def attributes_before_type_cast
    self.class.column_names.inject(HashWithIndifferentAccess.new) do |result, attribute_name|
      if attribute_name == self.class.hash_column
        result.merge(read_attribute(attribute_name) || {})
      else
        result.merge(attribute_name => read_attribute(attribute_name))
      end
    end
  end

  # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/attribute_methods/query.rb
  # http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Query.html
  # prefix: "", suffix: "?"
  def query_attribute(attribute_name)
    is_valid_hash_column_attribute_name?(attribute_name) || super(attribute_name)
  end

  # # http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods.html
  def [](attribute_name)
    read_attribute(attribute_name)
  end

  def []=(attribute_name, value)
    write_attribute(attribute_name, value)
  end

  def hash_column_attributes
    self.class.deserialize_hash_column_attribute(self.class.hash_column, read_attribute(self.class.hash_column))
  end

  def hash_column_attribute_names
    read_attribute(self.class.hash_column).keys.sort
  end

  def attribute_names
    ((self.class.column_names - [self.class.hash_column]) + hash_column_attribute_names).sort
  end

  def attributes
    (super || {}).with_indifferent_access.except(self.class.hash_column).merge(hash_column_attributes)
  end

  def column_for_attribute(attribute_name)
    attribute_name = attribute_name.to_s
    if is_valid_hash_column_attribute_name?(attribute_name)
      nil
    else
      super(attribute_name)
    end
  end

  def has_attribute?(attribute_name)
    attribute_name = attribute_name.to_s
    hash_column_attribute_names.include?(attribute_name) || super(attribute_name)
  end

  # http://api.rubyonrails.org/classes/ActiveRecord/AttributeAssignment.html
  # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/attribute_assignment.rb
  def assign_attributes(new_attributes)
    return if new_attributes.blank?
    new_attributes = new_attributes.with_indifferent_access
    __hash_column_attributes__ = new_attributes.except(*self.class.column_names)
    if __hash_column_attributes__.present?
      __hash_column_attributes__ = {self.class.hash_column => read_attribute(self.class.hash_column).merge(__hash_column_attributes__)}
      new_attributes = new_attributes.slice(*self.class.column_names).merge(__hash_column_attributes__)
    end
    super(new_attributes)
  end

  def to_h
    serializable_hash.with_indifferent_access
  end

  # http://api.rubyonrails.org/classes/ActiveRecord/Integration.html
  # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/integration.rb
  def cache_key
    "#{self.class.name.underscore.dasherize}-#{read_attribute(self.class.primary_key)}-version-#{Digest::MD5.hexdigest(attributes.inspect)}"
  end

  def inspect
    "#<#{self.class.name} #{attributes.map{ |k, v| "#{k}: #{v.inspect}" }.join(", ")}>"
  end

  def delete_hash_column_attribute(attribute_name)
    if is_valid_hash_column_attribute_name?(attribute_name)
      __hash_column_value__ = read_attribute(self.class.hash_column)
      __result__ = __hash_column_value__.delete(attribute_name)
      write_attribute(self.class.hash_column, __hash_column_value__)
      self.class.undefine_attribute_method(attribute_name)
      __result__
    else
      nil
    end
  end

  def update_columns(attributes)
    __hash_column_attributes__ = attributes.except(*self.class.column_names)
    if __hash_column_attributes__.present?
      __hash_column_attributes__ = self.class.serialize_hash_column_attribute(self.class.hash_column, __hash_column_attributes__)
      attributes = attributes.slice(*self.class.column_names).merge({self.class.hash_column => __hash_column_attributes__})
    end
    super(attributes)
  end

  def respond_to?(method_symbol, include_private = false)
    if super
      true 
    else
      attribute_name = self.class.extract_attribute_name(method_symbol)
      attribute_name.present? && hash_column_attribute_names.include?(attribute_name)
    end
  end

  def method_missing(method_symbol, *args, &block)
    attribute_name = self.class.extract_attribute_name(method_symbol)
    if attribute_name.present? &&
       self.class.column_names.include?(attribute_name) == false &&
       self.class.method_defined?(attribute_name) == false

        self.class.define_hash_column_attribute(attribute_name)
        __send__(method_symbol, *args)
    else
      super
    end
  end

  module ClassMethods
    def hash_column
      @hash_column ||= "__hash_column"
    end

    def hash_column=(column_name)
      raise ArgumentError, "column_name must be present" unless column_name.present?
      @hash_column = column_name.to_s
    end

    def extract_attribute_name(candidate_name)
      candidate_name = candidate_name.to_s
      return unless candidate_name.present?
      found_attribute_method_matchers = attribute_method_matchers.select{|m| m.plain? == false}.map{|m| m.match(candidate_name)}.compact
      attribute_method_match = found_attribute_method_matchers.sort_by{|m| m.target.length * -1}.first # make sure 'attribute_changed?' is selected before 'attribute?'
      attribute_name = attribute_method_match.try(:attr_name) || candidate_name
      return if attribute_name.to_sym.inspect.start_with?(':"')
      attribute_name
    end

    def is_valid_attribute_name?(attribute_name)
      attribute_name.to_s == extract_attribute_name(attribute_name)
    end

    def define_hash_column_attribute(name)
      attribute_name = extract_attribute_name(name)
      raise ArgumentError, "'#{name}'' is not a valid attribute name" unless attribute_name.present?
      unless method_defined?(attribute_name) || method_defined?("#{attribute_name}=")
        class_eval <<-RUBY
          def #{attribute_name}
            read_attribute('#{attribute_name}')
          end

          def #{attribute_name}=(value)
            write_attribute('#{attribute_name}', value)
          end
        RUBY
      end
      
      define_attribute_method attribute_name
    end

    def undefine_attribute_method(attribute_name)
      attribute_name = attribute_name.to_s
      generated_attribute_methods.synchronize do
        attribute_method_matchers.each do |matcher|
          method_name = matcher.method_name(attribute_name)
          undef_method(method_name) if method_defined?(method_name)
        end
        attribute_method_matchers_cache.clear
      end
    end

    # http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/TimeZoneConversion/ClassMethods.html
    # https://github.com/rails/rails/blob/4-0-stable/activerecord/lib/active_record/attribute_methods/time_zone_conversion.rb
    # Prevent error, since hash column attribute have no corresponding column object
    def create_time_zone_conversion_attribute?(name, column)
      if column # make sure column is not nil, since 'super' will check if column type is :datetime or :timestamp
        super(name, column)
      else
        false
      end
    end

    def value_serializers
      @value_serializers ||= []
    end

    def serialize_hash_column_attribute(attribute_name, value)
      serializer = value_serializers.select{|s| s.is_serializable?(value)}.first

      if serializer.present?
        serializer.new({}).dump(value)
      elsif value.is_a?(Hash)
        value.inject(HashWithIndifferentAccess.new) do |result, (key, value)|
          result[key] = serialize_hash_column_attribute("#{attribute_name}.#{key}", value)
          result
        end
      elsif value.is_a?(Array)
        value.map.with_index do |array_value, index|
          serialize_hash_column_attribute("#{attribute_name}[#{index}]", array_value)
        end
      else
        value
      end
    end

    def deserialize_hash_column_attribute(attribute_name, value)
      deserializer = value_serializers.select{|s| s.is_deserializable?(value)}.first

      if deserializer.present?
        deserializer.new({}).load(value)
      elsif value.is_a?(Hash)
        value.inject(HashWithIndifferentAccess.new) do |result, (key, value)|
          result[key] = deserialize_hash_column_attribute("#{attribute_name}.#{key}", value)
          result
        end
      elsif value.is_a?(Array)
        value.map.with_index do |array_value, index|
          deserialize_hash_column_attribute("#{attribute_name}[#{index}]", array_value)
        end
      else
        value
      end
    end

    def register_value_serializer(serializer_class)
      serializer_class = serializer_class.constantize if serializer_class.is_a?(String)
      deregister_value_serializer(serializer_class)
      value_serializers.insert(0, serializer_class)
    end

    def deregister_value_serializer(serializer_class)
      serializer_class = serializer_class.constantize if serializer_class.is_a?(String)
      value_serializers.delete(serializer_class)
    end
  end
end
