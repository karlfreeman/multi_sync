source "https://rubygems.org"

gem "rake", ">= 1.2"
gem "yard"

# platforms :ruby_18 do
# end
# platforms :ruby, :mswin, :mingw do
# end
# platforms :jruby do
# end

gem "sprockets", :require => false
gem "celluloid", :github => "celluloid/celluloid"
gem "multi_mime", :github => "karlfreeman/multi_mime"

group :development do
  gem "kramdown", ">= 0.14"
  gem "pry"
  gem "pry-debugger", :platforms => :mri_19
  gem "awesome_print"
end

group :test do
  gem "rspec"
  gem "rspec-smart-formatter"
  gem "fakefs", :github => "defunkt/fakefs", :require => "fakefs/safe"
  gem "timecop"
  gem "simplecov", :require => false
  gem "coveralls", :require => false
  gem "cane", :require => false
end

gemspec