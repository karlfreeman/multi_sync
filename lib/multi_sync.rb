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

  # a list of libraries and thier extension file
  REQUIREMENT_MAP = [
    ["rails", "multi_sync/extensions/rails"],
    ["middleman-core", "multi_sync/extensions/middleman"]
  ].freeze

  # delegate all MultiSync::Configuration's attribute accessors to the configuration
  def_delegators :configuration, *MultiSync::Configuration.attribute_set.map(&:name)

  # delegate all MultiSync::Configuration's attribute setters to the configuration ( hacky I know... )
  def_delegators :configuration, *(MultiSync::Configuration.attribute_set.map(&:name).map{ |key| "#{key}=".to_sym })

  # delegate all MultiSync::Client's attribute accessors to the configuration
  def_delegators :client, *MultiSync::Client.attribute_set.map(&:name)

  # include some public methods
  def_delegators :client, :target, :source, :synchronize

  # Configuration
  #
  # @return [MultiSync]
  def self.configure(&block)
    self.instance_eval(&block) if block_given?
    self
  end

  # Run
  #
  # @return [MultiSync]
  def self.run(&block)
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

  # by rescuing from a LoadError we can sniff out gems in use and try to automagically hook into them
  # REQUIREMENT_MAP.each do |(library, extension)|
  #   begin
  #     require library
  #     require extension
  #   rescue ::LoadError
  #     next
  #   end
  # end

end