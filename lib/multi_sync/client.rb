require "set"
require "virtus"
require "lazily"
require "celluloid"
require "multi_sync/sources/local_source"
require "multi_sync/targets/aws_target"
require "multi_sync/targets/local_target"

module MultiSync

  # Defines constants and methods related to the Client
  class Client
    include Virtus

    attr_accessor :supervisor
    attribute :incomplete_jobs, Set, :default => Set.new
    attribute :running_jobs, Set, :default => Set.new
    attribute :complete_jobs, Set, :default => Set.new
    attribute :sources, Array, :default => []
    attribute :sync_attempts, Integer, :default => 0
    attribute :file_sync_attempts, Integer, :default => 0
    attribute :started_at, Time
    attribute :finished_at, Time

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.supervisor = Celluloid::SupervisionGroup.run!
    end

    #
    def add_target(type, name, options={})
      begin
        clazz = MultiSync.const_get("#{type.capitalize.to_s}Target")
      rescue NameError
        MultiSync.error "Unknown target type: #{type}"
      end
      self.supervisor.pool(clazz, :as => name, :args => [options], :size => MultiSync.target_pool_size)
    end
    alias_method :target, :add_target

    #
    def add_source(type, name, opts={})
      begin
        clazz = MultiSync.const_get("#{type.capitalize.to_s}Source")
      rescue NameError
        MultiSync.error "Unknown source type: #{type}"
      end
      self.sources << clazz.new(opts)
    end
    alias_method :source, :add_source

    #
    def synchronize

      determine_sync if first_run?
      sync_attempted

      MultiSync.log "Scheduling job(s) in the future..."
      self.incomplete_jobs.delete_if do | job |
        self.running_jobs << { :id => job[:id], :future => Celluloid::Actor[job[:target_id]].future.send(job[:method], job[:args]) }
      end
      
      MultiSync.log "Fetching job(s) from the future(s)..."
      self.running_jobs.delete_if do | job |
        begin
          completed_job = { :id => job[:id], :response => job[:future].value }
        rescue
          self.file_sync_attempts = self.file_sync_attempts + 1
          false
        else
          self.complete_jobs << completed_job
          true
        end
      end

      finish_sync
      finalize

    end
    alias_method :sync, :synchronize

    #
    def finalize

      if self.finished_at
        MultiSync.log "Sync completed in #{(self.finished_at - self.started_at).to_i} seconds"
        MultiSync.log "#{self.complete_jobs.length} file(s) have been synchronised from #{self.sources.length} source(s) to #{self.supervisor.actors.length} target(s)"
        MultiSync.log "#{self.file_sync_attempts} failed request(s) were detected and re-tried"
      else
        MultiSync.log "Sync failed to complete with #{self.incomplete_jobs.length} outstanding file(s) to be synchronised"
        MultiSync.log "#{self.complete_jobs.length} file(s) were synchronised from #{self.sources.length} source(s) to #{self.supervisor.actors.length} target(s)"
      end

      self.supervisor.finalize
      
    end

    private

    #
    def determine_sync

      self.sources.lazily.each do |source|
        
        MultiSync.log "Synchronizing: '#{source.source_dir}'"
        
        source_files = source.files
        source_files.sort

        source.targets.lazily.each do | target_id |

          MultiSync.log "#{source_files.length} file(s) found from the source"

          MultiSync.log "Fetching file(s) from the target..."
          target_files = Celluloid::Actor[target_id].files
          target_files.sort
          MultiSync.log "#{target_files.length} file(s) found from the target"

          missing_files = determine_missing_files(source_files, target_files)
          MultiSync.log "#{missing_files.length} of the file(s) are missing"

          abandoned_files = determine_abandoned_files(source_files, target_files)
          MultiSync.log "#{abandoned_files.length} of the file(s) are abandoned"

          # remove missing_files from source_files ( as we know they are missing so don't need to check them )
          # remove abandoned_files from target_files ( as we know they are abandoned so don't need to check them )
          outdated_files = determine_outdated_files(source_files - missing_files, target_files - abandoned_files)
          MultiSync.log "#{outdated_files.length} of the file(s) are outdated"

          # abandoned files
          abandoned_files.lazily.each do | file |
            self.incomplete_jobs << { :id => SecureRandom.uuid, :target_id => target_id, :method => :delete, :args => file }
          end

          # missing files
          missing_files.lazily.each do | file |
            self.incomplete_jobs << { :id => SecureRandom.uuid, :target_id => target_id, :method => :upload, :args => file }
          end

          # outdated files
          outdated_files.lazily.each do | file |
            self.incomplete_jobs << { :id => SecureRandom.uuid, :target_id => target_id, :method => :upload, :args => file }
          end

        end

      end

    end

    #
    def determine_missing_files(source_files, target_files)
      missing_files = (source_files - target_files)
      return missing_files
    end

    #
    def determine_abandoned_files(source_files, target_files)
      abandoned_files = (target_files - source_files)
      return abandoned_files
    end

    #
    def determine_outdated_files(source_files, target_files)
      outdated_files = []

      # sort to make sure each array's indexs match
      source_files.sort
      target_files.sort

      # check each source file against the matching target_file's etag
      source_files.each_with_index do |file, i|
        outdated_files << file unless file.same?(target_files[i])
      end

      return outdated_files
    end

    #
    def sync_attempted
      self.started_at = Time.now if first_run?
      self.sync_attempts = self.sync_attempts + 1
      raise ArgumentError if self.sync_attempts > 10
    end

    #
    def finish_sync
      (self.incomplete_jobs.length != 0) ? self.synchronize : self.finished_at = Time.now
    end

    #
    def first_run?
      self.sync_attempts == 0
    end

  end

end