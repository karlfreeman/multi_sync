# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multi_sync/version'

Gem::Specification.new do |spec|
  spec.name          = 'multi_sync'
  spec.version       = MultiSync::VERSION
  spec.authors       = ['Karl Freeman']
  spec.email         = ['karlfreeman@gmail.com']
  spec.summary       = %q{Celluloid based, Fog::Storage backed, asset synchronisation library}
  spec.description   = %q{Celluloid based, Fog::Storage backed, asset synchronisation library}
  spec.homepage      = 'https://github.com/karlfreeman/multi_sync'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'fog', '~> 1.12'
  spec.add_dependency 'lazily', '~> 0.1'
  spec.add_dependency 'virtus', '~> 0.5'
  spec.add_dependency 'celluloid', '~> 0.15'
  spec.add_dependency 'multi_mime', '~> 0.0.3'
  spec.add_dependency 'multi_json', '~> 1.7'
  spec.add_dependency 'mime-types', '~> 1.21'
end
