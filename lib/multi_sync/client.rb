require "lazily"
require "multi_sync/sources/local_source"
require "multi_sync/targets/aws_target"
require "multi_sync/targets/local_target"

module MultiSync

  # Defines constants and methods related to the Client
  class Client

    # An array of valid keys in the options hash when configuring a Client
    VALID_OPTIONS_KEYS = [
      :sources
    ].freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.sources ||= []
    end

    #
    def sync

      work = []

      self.sources.each do | source |

        MultiSync.log "Synchronizing: '#{source.source_dir}'"

        source_files = source.files

        source.targets.each do | target |

          MultiSync.log "#{source_files.length} file(s) found from the source"

          target_files = target.files
          MultiSync.log "#{target_files.length} file(s) found from the target"

          outdated_files = (source_files - target_files)
          MultiSync.log "#{outdated_files.length} of the file(s) are outdated"

          abandoned_files = (target_files - source_files)
          MultiSync.log "#{abandoned_files.length} of the file(s) are abandoned"

          # abandoned files
          abandoned_files.each do | file |
            work << { :object => target, :method => :delete, :args => file }  
          end

          # outdated files
          outdated_files.each do | file |
            work << { :object => target, :method => :upload, :args => file }  
          end

        end

      end

      work.each do | job |
        job[:object].send(job[:method], job[:args])
      end

    end

  end

end