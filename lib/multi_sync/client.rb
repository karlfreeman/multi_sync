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

        MultiSync.log "Synchronizing: '#{source.source_dir}'"

        source_files = source.files

        source.targets.each do | target |

          MultiSync.log "#{source_files.length} source files found"

          target_files = target.files
          MultiSync.log "#{target_files.length} target files found"

          outdated_files = (source_files - target_files)
          MultiSync.log "#{outdated_files.length} outdated file(s)"

          abandoned_files = (target_files - source_files)
          MultiSync.log "#{abandoned_files.length} abandoned file(s)"

          # abandoned files
          abandoned_files.each do | file |
            target.delete(file)
          end

          # outdated files
          outdated_files.each do | file |
            target.upload(file)
          end

        end

      end

    end

  end

end