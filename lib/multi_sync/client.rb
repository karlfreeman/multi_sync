require "multi_sync/source"
require "multi_sync/aws_target"
require "multi_sync/local_target"

module MultiSync

  # Defines constants and methods related to the Client
  class Client

    attr_accessor :targets, :sources

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.targets ||= []
      self.sources ||= []
    end

    #
    def sync
      # self.sources.each do | source |
      #   source.files.each do | resource |
      #     source.targets.each do | target |
      #       target.async.sync(resource)
      #     end
      #   end
      # end
    end

  end

end