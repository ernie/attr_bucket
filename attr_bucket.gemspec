# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "attr_bucket/version"

Gem::Specification.new do |s|
  s.name        = "attr_bucket"
  s.version     = AttrBucket::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ernie Miller"]
  s.email       = ["ernie@metautonomo.us"]
  s.homepage    = "http://metautonomo.us"
  s.summary     = %q{This is probably a horrible idea.}
  s.description = %q{A really, really, horrible idea.}

  s.add_runtime_dependency(%q<activerecord>, ["~> 3.0.0"])

  s.rubyforge_project = "attr_bucket"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
