source "https://rubygems.org"

gem "rake", ">= 1.2"
gem "yard"

gem "fog", :git => "git://github.com/karlfreeman/fog.git"

# platforms :ruby_18 do
# end
# platforms :ruby, :mswin, :mingw do
# end
# platforms :jruby do
# end

group :development do
  gem "kramdown", ">= 0.14"
  gem "pry"
  gem "pry-debugger", :platforms => :mri_19
  gem "awesome_print"
end

group :test do
  gem "rspec"
  gem "rspec-smart-formatter"
  gem "fakefs", :require => "fakefs/safe"
  gem "simplecov", :require => false
  gem "coveralls", :require => false
  gem "cane"
end

gemspec