require 'virtus'
require 'pathname'
require 'celluloid'
require 'multi_sync/mixins/log_helper'

module MultiSync

  class Target
    include Virtus
    include Celluloid
    include MultiSync::Mixins::LogHelper

    attribute :connection
    attribute :target_dir, Pathname
    attribute :destination_dir, Pathname
    attribute :credentials, Hash, default: :default_credentials

    # Initialize a new Target object
    #
    # @param options [Hash]
    def initialize(options = {})
      raise(ArgumentError, 'target_dir must be present') unless options[:target_dir]
      self.target_dir = Pathname.new(options.fetch(:target_dir, ''))
      self.destination_dir = Pathname.new(options.fetch(:destination_dir, ''))
      credentials.merge!(options.fetch(:credentials, {}))
    end

    def default_credentials
      # deep clone just in case
      Marshal.load(Marshal.dump(MultiSync.credentials))
    end

  end

end
