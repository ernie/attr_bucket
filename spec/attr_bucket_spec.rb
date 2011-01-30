require 'spec_helper'

describe AttrBucket do

  it 'should define an private attr_bucket method in AR::Base' do
    ActiveRecord::Base.private_methods.should include :attr_bucket
  end

  it 'should define an i_has_a_bucket alias in AR::Base' do
    ActiveRecord::Base.private_methods.should include :i_has_a_bucket
  end

  it 'should raise an ArgumentError when defining a bucket on a non-text column' do
    expect { a_class_with_bucket :name => :blah }.to raise_error ArgumentError
  end

  context 'object with a bucketed attribute named "nickname"' do
    before do
      @o = an_object_with_bucket :bucket => :nickname
    end

    it 'should cast nickname to string' do
      @o.nickname = 42
      @o.nickname.should eq '42'
    end

    it 'should support validations' do
      @o.class.validates_presence_of :nickname
      expect { @o.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'should maintain bucketed attributes when saved' do
      @o.nickname = 'Headly von Headenstein'
      @o.save

      persisted_item.nickname.should eq 'Headly von Headenstein'
    end
  end

  context 'object with bucketed attributes in array format' do
    before do
      @o = an_object_with_bucket :bucket => [:quest, :favorite_color]
    end

    it 'should cast all values to strings' do
      @o.quest = 1
      @o.favorite_color = 2

      [@o.quest, @o.favorite_color].should eq ['1', '2']
    end
  end

  context 'object with bucketed attributes in hash format' do
    before do
      @o = an_object_with_bucket :bucket => {
        :summary           => :text,
        :age               => :integer,
        :body_temp         => :float,
        :salary            => :decimal,
        :hired_at          => :datetime,
        :stamp             => :timestamp,
        :workday_starts_at => :time,
        :birthday          => :date,
        :binary_data       => :binary,
        :is_awesome        => :boolean,
        :processed_name    => proc { |val| "PROCESSED: #{val}" }
      }
    end

    it 'typecasts to String for :text' do
      @o.summary = 12345
      @o.summary.should be_a String
      @o.summary.should eq '12345'
    end

    it 'typecasts to Fixnum for :integer' do
      @o.age = '33'
      @o.age.should be_a Fixnum
      @o.age.should eq 33
    end

    it 'typecasts to Float for :float' do
      @o.body_temp = '98.6'
      @o.body_temp.should be_a Float
      @o.body_temp.should eq 98.6
    end

    it 'typecasts to BigDecimal for :decimal' do
      @o.salary = '50000.23'
      @o.salary.should be_a BigDecimal
      @o.salary.should eq 50000.23
    end

    it 'typecasts to Time for :datetime as string' do
      @o.hired_at = '2011-01-01 08:00:00'
      @o.hired_at.should be_a Time
      @o.hired_at.should eq Time.parse '2011-01-01 08:00:00'
    end

    it 'typecasts to Time for :datetime as array' do
      @o.hired_at = [2011, 1, 1, 8, 0]
      @o.hired_at.should be_a Time
      @o.hired_at.should eq Time.local(2011, 1, 1, 8, 0)
    end

    it 'replaces a nil year with the current year in cast to Time' do
      @o.hired_at = [nil, 1, 1, 8, 0]
      @o.hired_at.should be_a Time
      @o.hired_at.should eq Time.local(Date.today.year, 1, 1, 8, 0)
    end

    it 'typecasts to Time for :timestamp' do
      @o.stamp = '2011-01-01 08:00:00'
      @o.stamp.should be_a Time
      @o.stamp.should eq Time.parse '2011-01-01 08:00:00'
    end

    it 'typecasts to dummy Time for :time' do
      @o.workday_starts_at = '08:00:00'
      @o.workday_starts_at.should be_a Time
      @o.workday_starts_at.should eq Time.parse '2000-01-01 08:00:00'
    end

    it 'typecasts to Date for :date as string' do
      @o.birthday = '1977/8/29'
      @o.birthday.should be_a Date
      @o.birthday.should eq Date.new(1977, 8, 29)
    end

    it 'typecasts to Date for :date as array' do
      @o.birthday = [1977,8,29]
      @o.birthday.should be_a Date
      @o.birthday.should eq Date.new(1977, 8, 29)
    end

    it 'typecasts to String for :binary' do
      @o.binary_data = File.read(__FILE__)
      @o.binary_data.should be_a String
      @o.binary_data.should match /@o.binary_data.should match/  # ooh, meta.
    end

    it 'typecasts to TrueClass/FalseClass for :boolean' do
      @o.is_awesome = '1'
      @o.should be_awesome
    end

    it 'performs custom processing when an attribute has a proc "type"' do
      @o.processed_name = 'Ernie'
      @o.processed_name.should be_a String
      @o.processed_name.should eq 'PROCESSED: Ernie'
    end

    it 'should raise ArgumentError if unable to typecast a value' do
      expect { @o.stamp = 123456 }.to raise_error ArgumentError
    end
  end
end