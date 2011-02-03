module AttrBucket
  def self.included(base) #:nodoc:
    base.extend ClassMethods
    base.class_attribute :bucketed_attributes
    base.bucketed_attributes = []
    base.instance_eval do
      alias_method_chain :assign_multiparameter_attributes, :attr_bucket
    end
  end

  private

  # Retrieve the attribute bucket, or if it's not yet a Hash,
  # initialize it as one.
  def get_attr_bucket(name)
    unless self[name].is_a?(Hash)
      self[name] = {}
    end
    self[name]
  end

  def valid_class(value, type)
    case type
      when :integer       then Fixnum === value
      when :float         then Float === value
      when :decimal       then BigDecimal === value
      when :datetime      then Time === value
      when :date          then Date === value
      when :timestamp     then Time === value
      when :time          then Time === value
      when :text, :string then String === value
      when :binary        then String === value
      when :boolean       then [TrueClass, FalseClass].grep value
      else false
    end
  end

  # We have to override assign_multiparameter_attributes to catch
  # dates/times for bucketed columns and handle them ourselves
  # before passing the remainder on for ActiveRecord::Base to handle.
  def assign_multiparameter_attributes_with_attr_bucket(pairs)
    bucket_pairs = pairs.select {|p| self.class.bucketed_attributes.include?(p.first.split('(').first)}
    extract_callstack_for_multiparameter_attributes(bucket_pairs).each do |name, value|
      send(name + '=', value.compact.empty? ? nil : value)
    end
    assign_multiparameter_attributes_without_attr_bucket(pairs - bucket_pairs)
  end

  # Swipe the nifty column typecasting from the column class
  # underlying the bucket column, or use the call method of
  # the object supplied for +type+ if it responds to call.
  #
  # This allows custom typecasting by supplying a proc, etc
  # as the value side of the hash in an attr_bucket definition.
  def explicitly_type_cast(value, type, column_class)
    return nil if value.nil?

    return type.call(value) if type.respond_to?(:call)

    typecasted = case type
      when :string    then value.to_s
      when :text      then value.to_s
      when :integer   then value.to_i rescue value ? 1 : 0
      when :float     then value.to_f
      when :decimal   then column_class.value_to_decimal(value)
      when :datetime  then cast_to_time(value, column_class)
      when :timestamp then cast_to_time(value, column_class)
      when :time      then cast_to_time(value, column_class, true)
      when :date      then cast_to_date(value, column_class)
      when :binary    then column_class.binary_to_string(value)
      when :boolean   then column_class.value_to_boolean(value)
      else value
    end

    raise ArgumentError, "Unable to typecast #{value} to #{type}" unless valid_class(typecasted, type)

    typecasted
  end

  def cast_to_date(value, column_class)
    if value.is_a?(Array)
      begin
        values = value.collect { |v| v.nil? ? 1 : v }
        Date.new(*values)
      rescue ArgumentError => e
        Time.time_with_datetime_fallback(self.class.default_timezone, *values).to_date
      end
    else
      column_class.string_to_date(value)
    end
  end

  def cast_to_time(value, column_class, dummy_time = false)
    if value.is_a?(Array)
      value[0] ||= Date.today.year
      Time.time_with_datetime_fallback(self.class.default_timezone, *value)
    else
      dummy_time ? column_class.string_to_dummy_time(value) : column_class.string_to_time(value)
    end
  end

  module ClassMethods
    private

    # Accepts an options hash of the format:
    #
    #   :<bucket-name> => <bucket-attributes>,
    #   [:<bucket-name> => <bucket-attributes>], [...]
    #
    # where <tt><bucket-name></tt> is the +text+ column being used for
    # serializing the objects, and <tt><bucket-attributes></tt> is:
    #
    # * A single attribute name in symbol format (not much point...)
    # * An array of attribute names
    # * A hash, in which the keys are the attribute names in Symbol format,
    #   and the values describe what they should be typecast as. The valid
    #   choices are +string+, +text+, +integer+, +float+, +decimal+, +datetime+,
    #   +timestamp+, +time+, +date+, +binary+, or +boolean+. This will invoke
    #   the same typecasting behavior as is normally used by the underlying
    #   ActiveRecord column (specific to your database).
    #
    # Alternately, you may specify a Proc or another object that responds to
    # +call+, and it will be invoked with the value being assigned to the
    # attribute as its only parameter, for custom typecasting behavior.
    #
    # Example:
    #
    #   attr_bucket :bucket => {
    #     :is_awesome       => :boolean
    #     :circumference    => :integer,
    #     :flanderized_name => proc {|val| "#{val}-diddly"}
    #   }
    def attr_bucket(opts = {})
      opts.map do |bucket_name, attrs|
        bucket_column = self.columns_hash[bucket_name.to_s]
        unless bucket_column.type == :text
          raise ArgumentError,
                "#{bucket_name} is of type #{bucket_column.type}, not text"
        end
        serialize bucket_name, Hash

        if attrs.is_a?(Hash)
          attrs.map do|attr_name, attr_type|
            define_bucket_reader bucket_name, attr_name
            define_bucket_writer bucket_name, attr_name, attr_type, bucket_column.class
          end
        else
          Array.wrap(attrs).each do |attr_name|
            define_bucket_reader bucket_name, attr_name
            define_bucket_writer bucket_name, attr_name, :string, bucket_column.class
          end
        end
      end
    end

    alias :i_has_a_bucket :attr_bucket

    def define_bucket_reader(bucket_name, attr_name) #:nodoc:
      self.bucketed_attributes += [attr_name.to_s]
      define_method attr_name do
        get_attr_bucket(bucket_name)[attr_name]
      end unless method_defined? attr_name
    end

    def define_bucket_writer(bucket_name, attr_name, attr_type, column_class) #:nodoc:
      define_method "#{attr_name}=" do |val|
        # TODO: Make this more resilient/granular for multiple bucketed changes
        send("#{bucket_name}_will_change!")
        typecasted = explicitly_type_cast(val, attr_type, column_class)
        get_attr_bucket(bucket_name)[attr_name] = typecasted
      end unless method_defined? "#{attr_name}="
    end
  end
end

require 'active_record'

ActiveRecord::Base.send(:include, AttrBucket)