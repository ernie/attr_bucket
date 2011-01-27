module AttrBucket
  def self.included(base)
    base.extend ClassMethods
  end

  private

  def get_attr_bucket(name)
    unless read_attribute(name).is_a?(Hash)
      write_attribute(name, {})
    end
    read_attribute(name)
  end

  def explicitly_type_cast(value, type, column_class)
    return nil if value.nil?
    case type
      when :string    then value.to_s
      when :text      then value.to_s
      when :integer   then value.to_i rescue value ? 1 : 0
      when :float     then value.to_f
      when :decimal   then column_class.value_to_decimal(value)
      when :datetime  then column_class.string_to_time(value)
      when :timestamp then column_class.string_to_time(value)
      when :time      then column_class.string_to_dummy_time(value)
      when :date      then column_class.string_to_date(value)
      when :binary    then column_class.binary_to_string(value)
      when :boolean   then column_class.value_to_boolean(value)
      else value
    end
  end

  module ClassMethods
    private

    def attr_bucket(opts = {})
      opts.map do |bucket_name, attrs|
        bucket_column = self.columns_hash[bucket_name.to_s]
        unless bucket_column.type == :text
          raise ArgumentError,
                "#{bucket_name} is a #{bucket_column.type} column, not text"
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

    def define_bucket_reader(bucket_name, attr_name)
      define_method attr_name do
        get_attr_bucket(bucket_name)[attr_name]
      end unless method_defined? attr_name
    end

    def define_bucket_writer(bucket_name, attr_name, attr_type, column_class)
      define_method "#{attr_name}=" do |val|
        # TODO: Make this more resilient/granular for multiple bucketed changes
        send("#{bucket_name}_will_change!")
        get_attr_bucket(bucket_name)[attr_name] = explicitly_type_cast(val, attr_type, column_class)
      end unless method_defined? "#{attr_name}="
    end
  end
end

require 'active_record'

ActiveRecord::Base.send(:include, AttrBucket)