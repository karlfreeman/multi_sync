require 'timecop'
RSpec.configure do |config|
  config.around do |ex|
    Timecop.freeze do
      ex.run
    end
  end
end