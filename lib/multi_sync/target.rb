require "pathname"

module MultiSync

  # Defines constants and methods related to the Target
  class Target

    # An array of valid keys in the options hash when configuring a Target
    VALID_OPTIONS_KEYS = [
      :target_dir,
      :destination_dir,
      :credentials,
      :connection
    ].freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)
    
    # Initialize a new Target object
    #
    # @param options [Hash]
    def initialize(options = {})
      # raise(ArgumentError, "destination_dir must be present") unless options[:destination_dir]
      # raise(ArgumentError, "provider must be present and a symbol") unless options[:provider] && options[:provider].is_a?(Symbol)
      self.target_dir = Pathname.new(options.delete(:target_dir))
      self.destination_dir = Pathname.new(options.delete(:destination_dir))
      self.credentials = options.delete(:credentials) { {} }
    end

  end

end