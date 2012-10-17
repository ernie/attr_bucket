# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "attr_bucket/version"

Gem::Specification.new do |s|
  s.name        = "attr_bucket"
  s.version     = AttrBucket::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ernie Miller"]
  s.email       = ["ernie@erniemiller.org"]
  s.homepage    = "http://erniemiller.org"
  s.summary     = %q{Your model can has a bucket (for its attributes).}
  s.description = %q{Store a few extra (non-searchable) attributes away in a bucket. This is probably a horrible idea, but try it anyway.}

  s.add_runtime_dependency 'activerecord', '~> 3.0'
  s.add_development_dependency 'rspec', '~> 2.11.0'
  s.add_development_dependency 'sqlite3'

  s.rubyforge_project = "attr_bucket"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
