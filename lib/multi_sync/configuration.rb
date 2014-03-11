require 'virtus'
require 'fog'
require 'celluloid'

module MultiSync
  class Configuration
    include Virtus.model

    attribute :verbose, Boolean, default: false
    attribute :force, Boolean, default: false
    attribute :run_on_build, Boolean, default: true
    attribute :delete_abandoned_files, Boolean, default: true
    attribute :upload_missing_files, Boolean, default: true
    attribute :target_pool_size, Integer, default: :celluloid_cores
    attribute :max_sync_attempts, Integer, default: 3
    attribute :credentials, Hash, default: :fog_credentials

    # Initialize a new Configuration object
    #
    # @param options [Hash]
    def initialize(*args)
      # Celluloid.logger = MultiSync.verbose? ? nil : MultiSync.logger
      Celluloid.logger = nil
      super
    end

    private

    def celluloid_cores
      Celluloid.cores < 2 ? 2 : Celluloid.cores 
    end

    def fog_credentials
      Fog.credentials
    end
  end
end
