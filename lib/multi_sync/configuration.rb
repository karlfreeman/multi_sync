require "fog"
require "celluloid"
module MultiSync

  # Defines constants and methods related to the Configuration
  class Configuration

    # An array of valid keys in the options hash when configuring a `MultiSync::Configuration`
    VALID_OPTIONS_KEYS = [
      :verbose,
      :target_pool_size,
    ].freeze

    # A hash of valid options and their default values
    DEFAULT_OPTIONS = {
      :verbose => false,
      :target_pool_size => Celluloid.cores
    }.freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)

    # Initialize a new Configuration object
    #
    # @param options [Hash]
    def initialize(options = {})
      reset_options
      options.each_pair do |key, value|
        send("#{key}=", value) if VALID_OPTIONS_KEYS.include?(key)
      end
    end

    #
    def credentials
      ::Fog.credentials
    end

    private

    # Create a hash of options and their values
    def valid_options
      VALID_OPTIONS_KEYS.inject({}){|o,k| o.merge!(k => send(k)) }
    end

    # Create a hash of the default options and their values
    def default_options
      DEFAULT_OPTIONS
    end

    # Set the VALID_OPTIONS_KEYS with their DEFAULT_OPTIONS
    def reset_options
      VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", default_options[key])
      end
    end

  end

end