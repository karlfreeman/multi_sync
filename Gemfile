source "https://rubygems.org"

gem "rake", ">= 1.2"
gem "yard"

# platforms :ruby_18 do
# end
# platforms :ruby, :mswin, :mingw do
# end
# platforms :jruby do
# end

gem "celluloid", :git => "git://github.com/celluloid/celluloid.git"
gem "fog", :git => "git://github.com/fog/fog.git"

group :development do
  gem "kramdown", ">= 0.14"
  gem "pry"
  gem "pry-debugger", :platforms => :mri_19
  gem "awesome_print"
end

group :test do
  gem "rspec"
  gem "rspec-smart-formatter"
  gem "fakefs", :git => "https://github.com/defunkt/fakefs.git", :require => "fakefs/safe"
  gem "simplecov", :require => false
  gem "coveralls", :require => false
  gem "cane", :require => false
end

gemspec