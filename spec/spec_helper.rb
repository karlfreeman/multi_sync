$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler"
Bundler.setup
begin; require "awesome_print"; rescue LoadError; end

require "rspec"
require "securerandom"

require "support/pry"
require "support/fakefs"
require "support/timecop"
require "support/simplecov"

require "multi_sync"

require 'celluloid/test'

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    MultiSync.reset!
    MultiSync.env = :test
    MultiSync.verbose = true
  end

end