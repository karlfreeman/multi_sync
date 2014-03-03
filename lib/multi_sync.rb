require 'forwardable'
require 'multi_sync/client'
require 'multi_sync/version'
require 'multi_sync/logging'
require 'multi_sync/environment'
require 'multi_sync/configuration'

module MultiSync
  extend SingleForwardable
  extend MultiSync::Logging
  extend MultiSync::Environment

  # a list of libraries, extension file and class name
  REQUIREMENT_MAP = [
    ['rails', 'multi_sync/extensions/rails'],
    ['middleman-core', 'multi_sync/extensions/middleman']
  ].freeze

  # delegate all MultiSync::Configuration's attribute accessors to the configuration
  def_delegators :configuration, *MultiSync::Configuration.attribute_set.map(&:name)

  # delegate all MultiSync::Configuration's attribute setters to the configuration ( hacky I know... )
  def_delegators :configuration, *(MultiSync::Configuration.attribute_set.map(&:name).map { |key| "#{key}=".to_sym })

  # delegate all MultiSync::Client's attribute accessors to the configuration
  def_delegators :client, *MultiSync::Client.attribute_set.map(&:name)

  # include some public methods
  def_delegators :client, :target, :source, :synchronize

  # Configure
  #
  # @return [MultiSync]
  def self.configure(&block)
    instance_eval(&block) if block_given?
    self
  end

  # Run
  #
  # @return [MultiSync]
  def self.run(&block)
    configure(&block).synchronize
  end

  # Prepare
  #
  # @return [MultiSync]
  def self.prepare(&block)
    configure(&block)
  end

  # Fetch the MultiSync::Client
  #
  # @return [MultiSync::Client]
  def self.client(options = {})
    @client ||= MultiSync::Client.new(options)
  end

  # Fetch the MultiSync::Configuration
  #
  # @return [MultiSync::Configuration]
  def self.configuration(options = {})
    @configuration ||= MultiSync::Configuration.new(options)
  end

  # Reset the MultiSync::Client
  def self.reset_client!
    remove_instance_variable :@client if defined?(@client)
  end

  # Reset the MultiSync::Configuration
  def self.reset_configuration!
    remove_instance_variable :@configuration if defined?(@configuration)
  end

  # Reset MultiSync::Configuration and MultiSync::Client
  def self.reset!
    self.reset_client!
    self.reset_configuration!
  end

  # by rescuing from a LoadError we can sniff out gems in use and try to automagically hook into them
  REQUIREMENT_MAP.each do |library, extension|
    begin
      require library
      require extension
    rescue ::LoadError
      next
    end
  end
end
