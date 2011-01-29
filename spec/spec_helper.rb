require 'rubygems'
require 'bundler/setup'
require 'attr_bucket'

Dir[File.expand_path('../{helpers,support}/*.rb', __FILE__)].each do |f|
  require f
end

RSpec.configure do |config|
  config.before :suite do
    Schema.create
  end

  config.include AttrBucketHelper
end