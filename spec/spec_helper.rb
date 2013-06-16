$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler"
Bundler.setup
begin; require "awesome_print"; rescue LoadError; end

require "rspec"
require "securerandom"

require "support/pry"
require "support/fakefs"
require "support/simplecov"

require "multi_sync"
MultiSync.env = :test
MultiSync.log = false

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Celluloid.shutdown
    MultiSync.instance_variable_set('@client', nil)
    MultiSync.instance_variable_set('@configuration', nil)
    Celluloid.boot
  end

end