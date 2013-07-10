require "fog"
require "virtus"
require "celluloid"
Fog::Logger[:warning] = nil

module MultiSync

  # Defines constants and methods related to the Configuration
  class Configuration
    include Virtus

    attribute :verbose, Boolean, :default => false
    attribute :run_on_build, Boolean, :default => true
    attribute :delete_abandoned_files, Boolean, :default => true
    attribute :upload_missing_files, Boolean, :default => true
    attribute :target_pool_size, Integer, :default => :celluloid_cores
    attribute :max_sync_attempts, Integer, :default => 3
    attribute :credentials, Hash, :default => :fog_credentials

    # Initialize a new Configuration object
    #
    # @param options [Hash]
    def initialize(options = {})
      Celluloid.logger = MultiSync.logger
      options.each_pair do |key, value|
        send("#{key}=", value) if self.attributes.keys.include?(key)
      end
    end

    #
    def celluloid_cores
      Celluloid.cores
    end

    #
    def fog_credentials
      Fog.credentials
    end

  end

end