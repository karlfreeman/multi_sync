require "set"
require "virtus"
require "lazily"
require "celluloid"
require "multi_sync/sources/local_source"
require "multi_sync/sources/manifest_source"
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
    def add_target(name, options={})
      begin
        clazz = MultiSync.const_get("#{options[:type].capitalize.to_s}Target")
      rescue NameError
        # TODO custom exceptions
        MultiSync.warn "Unknown target type: #{options[:type]}"
        raise ArgumentError, "Unknown target type: #{options[:type]}"
      end
      self.supervisor.pool(clazz, :as => name, :args => [options], :size => MultiSync.target_pool_size)
    end
    alias_method :target, :add_target

    #
    def add_source(name, options={})
      begin
        clazz = MultiSync.const_get("#{options[:type].capitalize.to_s}Source")
      rescue NameError
        # TODO custom exceptions
        MultiSync.warn "Unknown source type: #{options[:type]}"
        raise ArgumentError, "Unknown source type: #{options[:type]}"
      end
      self.sources << clazz.new(options)
    end
    alias_method :source, :add_source

    #
    def synchronize

      if sync_pointless?
        MultiSync.info "Preventing synchronization as there are #{self.sources.length} sources to sync..."
        return
      else
        MultiSync.info "Starting synchronization..."
      end

      determine_sync if first_run?
      sync_attempted

      MultiSync.debug "Scheduling job(s) in the future..."
      self.incomplete_jobs.delete_if do | job |
        self.running_jobs << { :id => job[:id], :future => Celluloid::Actor[job[:target_id]].future.send(job[:method], job[:args]) }
      end
      
      MultiSync.debug "Fetching job(s) from the future(s)..."
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
        MultiSync.info "Sync completed in #{(self.finished_at - self.started_at).to_i} seconds"
        MultiSync.info "#{self.complete_jobs.length} file(s) have been synchronised from #{self.sources.length} source(s) to #{self.supervisor.actors.length} target(s)"
        MultiSync.info "#{self.file_sync_attempts} failed request(s) were detected and re-tried"
      else
        MultiSync.info "Sync failed to complete with #{self.incomplete_jobs.length} outstanding file(s) to be synchronised"
        MultiSync.info "#{self.complete_jobs.length} file(s) were synchronised from #{self.sources.length} source(s) to #{self.supervisor.actors.length} target(s)"
      end

      self.supervisor.finalize
      
    end
    alias_method :fin, :finalize

    private

    #
    def determine_sync

      self.sources.lazily.each do |source|

        source_files = []

        MultiSync.info "Synchronizing: '#{source.source_dir}'"
        
        source_files = source.files
        source_files.sort! # sort to make sure the source's indexs match the targets

        source.targets.lazily.each do | target_id |

          missing_files = []
          abandoned_files = []
          outdated_files = []

          MultiSync.debug "#{source_files.length} file(s) found from the source"

          MultiSync.debug "Fetching file(s) from the target..."

          target_files = Celluloid::Actor[target_id].files
          target_files.sort! # sort to make sure the target's indexs match the sources

          MultiSync.debug "#{target_files.length} file(s) found from the target"
          
          missing_files = determine_missing_files(source_files, target_files)
          missing_files_msg = "#{missing_files.length} of the file(s) are missing"
          missing_files_msg += ", however we're skipping them as :upload_missing_files is false" unless MultiSync.upload_missing_files
          MultiSync.debug missing_files_msg

          abandoned_files = determine_abandoned_files(source_files, target_files)
          abandoned_files_msg = "#{abandoned_files.length} of the file(s) are abandoned"
          abandoned_files_msg += ", however we're skipping them as :delete_abandoned_files is false" unless MultiSync.delete_abandoned_files
          MultiSync.debug abandoned_files_msg

          # remove missing_files from source_files ( as we know they are missing so don't need to check them )
          # remove abandoned_files from target_files ( as we know they are abandoned so don't need to check them )
          outdated_files = determine_outdated_files(source_files - missing_files, target_files - abandoned_files)
          MultiSync.debug "#{outdated_files.length} of the file(s) are outdated"

          # abandoned files
          abandoned_files.lazily.each do | file |
            self.incomplete_jobs << { :id => Celluloid.uuid, :target_id => target_id, :method => :delete, :args => file }
          end if MultiSync.delete_abandoned_files

          # missing files
          missing_files.lazily.each do | file |
            self.incomplete_jobs << { :id => Celluloid.uuid, :target_id => target_id, :method => :upload, :args => file }
          end if MultiSync.upload_missing_files

          # outdated files
          outdated_files.lazily.each do | file |
            self.incomplete_jobs << { :id => Celluloid.uuid, :target_id => target_id, :method => :upload, :args => file }
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

      # TODO replace with celluloid pool of futures
      # check each source file against the matching target_file's etag
      source_files.lazily.each_with_index do |file, i|
        outdated_files << file unless file.has_matching_etag?(target_files[i])
      end

      return outdated_files

    end

    #
    def sync_attempted
      self.started_at = Time.now if first_run?
      self.sync_attempts = self.sync_attempts + 1
      if self.sync_attempts > MultiSync.max_sync_attempts
        # TODO custom exceptions
        MultiSync.warn "Sync was attempted more then #{MultiSync.max_sync_attempts} times"
        raise ArgumentError, "Sync was attempted more then #{MultiSync.max_sync_attempts} times"
      end
    end

    #
    def finish_sync
      (self.incomplete_jobs.length != 0) ? self.synchronize : self.finished_at = Time.now
    end

    #
    def first_run?
      self.sync_attempts == 0
    end

    def sync_pointless?
      self.sources.empty?
    end

  end

end