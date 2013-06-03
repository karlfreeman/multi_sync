# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "multi_sync/version"

Gem::Specification.new do |gem|
  gem.add_dependency "fog", "~> 1.10"
  gem.add_dependency "lazily", "~> 0.1"
  gem.add_dependency "celluloid", "~> 0.14"
  gem.add_dependency "log_switch", "~> 0.4"
  gem.add_dependency "multi_mime", "~> 0.0.1"
  gem.add_dependency "state_machine", "~> 1.2"
  gem.add_dependency "connection_pool", "~> 1.0"
  gem.add_development_dependency "bundler", "~> 1.0"
  gem.name          = "multi_sync"
  gem.version       = MultiSync::VERSION
  gem.authors       = ["Karl Freeman"]
  gem.email         = ["karlfreeman@gmail.com"]
  gem.license       = "MIT"
  gem.description   = %q{Celluloid based, Fog::Storage backed, asset synchronisation library}
  gem.summary       = %q{Celluloid based, Fog::Storage backed, asset synchronisation library}
  gem.homepage      = "https://github.com/karlfreeman/multi_sync"
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.required_ruby_version = ">= 1.9.2"
end