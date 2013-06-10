require "virtus"
require "pathname"
require "celluloid"

module MultiSync

  # Defines constants and methods related to the Target
  class Target
    include Virtus
    include Celluloid

    attr_accessor :connection
    attribute :target_dir, Pathname
    attribute :destination_dir, Pathname
    attribute :credentials, Hash, :default => :default_credentials
    
    # Initialize a new Target object
    #
    # @param options [Hash]
    def initialize(options = {})
      # raise(ArgumentError, "destination_dir must be present") unless options[:destination_dir]
      # raise(ArgumentError, "provider must be present and a symbol") unless options[:provider] && options[:provider].is_a?(Symbol)
      self.target_dir = Pathname.new(options.delete(:target_dir))
      self.destination_dir = Pathname.new(options.delete(:destination_dir))
      self.credentials.merge!(options.delete(:credentials){ Hash.new })
    end

    def default_credentials
      Marshal.load(Marshal.dump(MultiSync.credentials))
    end

  end

end