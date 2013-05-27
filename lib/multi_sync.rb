require "forwardable"
require "log_switch"
require "multi_sync/version"
require "multi_sync/environment"
require "multi_sync/client"
require "multi_sync/configuration"
require "multi_sync/cli"

# REQUIREMENT_MAP = [
#   ["rails", "multi_sync/extensions/rails"]
# ]

# REQUIREMENT_MAP.each do |(library, extension)|
#   begin
#     require library
#     require extension
#   rescue ::LoadError
#     next
#   end
# end

module MultiSync
  extend SingleForwardable
  extend LogSwitch
  extend MultiSync::Environment

  # delegate all VALID_OPTIONS_KEYS accessors to the configuration
  def_delegators :configuration, *MultiSync::Configuration::VALID_OPTIONS_KEYS

  # delegate all VALID_OPTIONS_KEYS setters to the configuration ( hacky I know... )
  def_delegators :configuration, *(MultiSync::Configuration::VALID_OPTIONS_KEYS.dup.collect! do |key| "#{key}=".to_sym; end)

  # Configures a new Client object
  #
  # @return [MultiSync]
  def self.configure(&block)
    yield self if block_given?
    self
  end

  # Fetch the MultiSync::Client
  #
  # @return [MultiSync::Client]
  def self.client(options={})
    @client ||= MultiSync::Client.new(options)
  end

  # Fetch the MultiSync::Configuration
  #
  # @return [MultiSync::Configuration]
  def self.configuration(options={})
    @configuration ||= MultiSync::Configuration.new(options)
  end

end