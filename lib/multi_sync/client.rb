require "parallel"
require "multi_sync/source"
require "multi_sync/aws_target"
require "multi_sync/local_target"

module MultiSync

  # Defines constants and methods related to the Client
  class Client

    attr_accessor :targets, :sources, :outdated_files, :abandoned_files

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.targets ||= []
      self.sources ||= []
      self.outdated_files ||= []
      self.abandoned_files ||= []
    end

    #
    def determine_files
      self.sources.each do | source |
        source.targets.each do | target |
          self.outdated_files.concat (source.files - target.files)
          self.abandoned_files.concat (target.files - source.files)
        end
      end
    end

    def sync_outdated_files
      self.outdated_files.each do | resource |
        ap resource.path_with_root
      end
    end

    def remove_abandoned_files
      self.abandoned_files.each do | resource |
        ap resource.path_with_root
      end
    end

  end

end