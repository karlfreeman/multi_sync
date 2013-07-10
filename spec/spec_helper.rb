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
Celluloid.shutdown_timeout = 1

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    MultiSync.reset!
    MultiSync.env = :test
    MultiSync.verbose = true
    Celluloid.shutdown
    sleep 0.01
    Celluloid.internal_pool.assert_inactive
    Celluloid.boot
  end

end