require "log_switch"
require "forwardable"
require "multi_sync/client"
require "multi_sync/version"
require "multi_sync/environment"
require "multi_sync/configuration"

module MultiSync
  extend SingleForwardable
  extend LogSwitch
  extend MultiSync::Environment

  # delegate all VALID_OPTIONS_KEYS accessors to the configuration
  def_delegators :configuration, *MultiSync::Configuration::VALID_OPTIONS_KEYS

  # delegate all VALID_OPTIONS_KEYS setters to the configuration ( hacky I know... )
  def_delegators :configuration, *(MultiSync::Configuration::VALID_OPTIONS_KEYS.dup.collect!{ |key| "#{key}=".to_sym })

  # more delegation
  def_delegators :client, :target, :source, :synchronize

  # a list of libraries and thier extension file
  REQUIREMENT_MAP = [
    ["rails", "multi_sync/extensions/rails"],
    ["middleman-core", "multi_sync/extensions/middleman"]
  ].freeze

  # by rescuing from a LoadError we can sniff out gems in use and try to automagically hook into them
  REQUIREMENT_MAP.each do |(library, extension)|
    begin
      require library
      require extension
    rescue ::LoadError
      next
    end
  end

  # Configuration
  #
  # @return [MultiSync]
  def self.configure(&block)
    self.instance_eval(&block) if block_given?
    self
  end

  # Synchronize
  #
  # @return [MultiSync]
  def self.sync(&block)
    self.configure(&block).synchronize
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