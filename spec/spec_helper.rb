$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler"
Bundler.setup
begin; require "awesome_print"; rescue LoadError; end

require "rspec"

require "support/pry"
require "support/simplecov"

require "multi_sync"

# used as a stupid mixin class
class DummyClass
end

#
RSpec.configure do |config|

  #
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  #
  def jruby?
    defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  end

  #
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

end