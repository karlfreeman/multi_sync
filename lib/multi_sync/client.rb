require "multi_sync/source"
require "multi_sync/targets/aws_target"
require "multi_sync/targets/local_target"

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

      self.sources.each do | source |

        source.targets.each do | target |

          # abandoned files
          (target.files - source.files).each do | file |
            file.remove!
          end

          # outdated files
          (source.files - target.files).each do | file |
            target.sync(file)
          end

        end

      end

    end

  end

end