source 'https://rubygems.org'

gem 'rake', '~> 10.0'
gem 'yard'

gem 'sprockets', :require => false

group :development do
  gem 'kramdown', '>= 0.14'
  gem 'pry'
  gem 'pry-debugger', :platforms => :mri_19
  gem 'awesome_print'
end

group :test do
  gem 'rspec'
  gem 'rspec-smart-formatter'
  gem 'fakefs', :github => 'defunkt/fakefs', :require => 'fakefs/safe'
  gem 'timecop'
  gem 'simplecov', :require => false
  gem 'coveralls', :require => false
  gem 'cane', :require => false
end

gemspec
