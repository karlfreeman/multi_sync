require 'set'
require 'virtus'
require 'lazily'
require 'celluloid'
require 'multi_sync/sources/local_source'
require 'multi_sync/sources/manifest_source'
require 'multi_sync/targets/aws_target'
require 'multi_sync/targets/local_target'
require 'multi_sync/mixins/pluralize_helper'

module MultiSync
  # Defines constants and methods related to the Client
  class Client
    include Virtus
    include MultiSync::Mixins::PluralizeHelper

    attribute :supervisor
    attribute :incomplete_jobs, Set, default: Set.new
    attribute :running_jobs, Set, default: Set.new
    attribute :complete_jobs, Set, default: Set.new
    attribute :sources, Array, default: []
    attribute :sync_attempts, Integer, default: 0
    attribute :file_sync_attempts, Integer, default: 0
    attribute :started_at, Time
    attribute :finished_at, Time

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.supervisor = Celluloid::SupervisionGroup.run!
    end

    #
    def add_target(name, options = {})
      raise ArgumentError, "Duplicate target names detected, please rename '#{name}' to be unique" if supervisor_actor_names.include?(name)
      begin
        clazz = MultiSync.const_get("#{options[:type].capitalize.to_s}Target")
        supervisor.pool(clazz, as: name, args: [options], size: MultiSync.target_pool_size)
      rescue NameError
        MultiSync.warn "Unknown target type: #{options[:type]}"
        raise ArgumentError, "Unknown target type: #{options[:type]}"
      end
    end
    alias_method :target, :add_target

    #
    def add_source(name, options = {})
      begin
        clazz = MultiSync.const_get("#{options[:type].capitalize.to_s}Source")
        sources << clazz.new(options)
      rescue NameError
        MultiSync.warn "Unknown source type: #{options[:type]}"
        raise ArgumentError, "Unknown source type: #{options[:type]}"
      end
    end
    alias_method :source, :add_source

    #
    def synchronize
      if sync_pointless?
        MultiSync.debug "Preventing synchronization as there are #{sources.length} sources to sync..."
        return
      else
        MultiSync.debug 'Starting synchronization...'
      end

      determine_sync if first_run?
      sync_attempted

      MultiSync.debug 'Scheduling jobs in the future...'
      incomplete_jobs.delete_if do | job |
        running_jobs << { id: job[:id], future: Celluloid::Actor[job[:target_id]].future.send(job[:method], job[:args]), method: job[:method] }
      end

      MultiSync.debug 'Fetching jobs from the future...'
      running_jobs.delete_if do | job |
        begin
          completed_job = { id: job[:id], response: job[:future].value, method: job[:method] }
        rescue
          self.file_sync_attempts = file_sync_attempts + 1
          false
        else
          complete_jobs << completed_job
          true
        end
      end

      finish_sync
      finalize
    end
    alias_method :sync, :synchronize

    #
    def finalize
      if finished_at
        # elapsed = self.finished_at.to_f - self.started_at.to_f
        # minutes, seconds = elapsed.divmod 60.0
        # kilobytes = get_total_file_size_from_complete_jobs / 1024.0
        # MultiSync.debug "Sync completed in #{pluralize(minutes.round, 'minute')} and #{pluralize(seconds.round, 'second')}"
        # MultiSync.debug "#{pluralize(self.complete_jobs.length, 'file')} were synchronised (#{pluralize(get_complete_deleted_jobs.length, 'deleted file')} and #{pluralize(get_complete_upload_jobs.length, 'uploaded file')}) from #{pluralize(self.sources.length, 'source')} to #{pluralize(self.supervisor.actors.length, 'target')}"
        # MultiSync.debug "The upload weight totalled %.#{0}f #{pluralize(kilobytes, 'KB', 'KB', false)}" % kilobytes
        # MultiSync.debug "#{pluralize(self.file_sync_attempts, 'failed request')} were detected and re-tried"
      else
        # MultiSync.debug "Sync failed to complete with #{pluralize(self.incomplete_jobs.length, 'outstanding file')} to be synchronised"
        # MultiSync.debug "#{pluralize(self.complete_jobs.length, 'file')} were synchronised (#{pluralize(get_complete_deleted_jobs.length, 'deleted file')} and #{pluralize(get_complete_upload_jobs.length, 'uploaded file')}) from #{pluralize(self.sources.length, 'source')} to #{pluralize(self.supervisor.actors.length, 'target')}"
      end

      supervisor.finalize
    end
    alias_method :fin, :finalize

    #
    def get_complete_deleted_jobs
      complete_jobs.select { |job| job[:method] == :delete }
    end

    #
    def get_complete_upload_jobs
      complete_jobs.select { |job| job[:method] == :upload }
    end

    #
    def get_total_file_size_from_complete_jobs
      total_file_size = 0
      get_complete_upload_jobs.each do | job |
        # MultiSync.info job[:response]
        # MultiSync.info job[:response].determine_content_length
        if job[:response].content_length
          total_file_size = total_file_size + job[:response].content_length
        end

      end
      total_file_size
    end

    private

    #
    def determine_sync
      sources.lazily.each do |source|

        source_files = []

        starting_synchronizing_msg = "ynchronizing: '#{source.source_dir}'"
        starting_synchronizing_msg.prepend MultiSync.force ? 'Forcefully s' : 'S'
        MultiSync.info starting_synchronizing_msg

        source_files = source.files
        source_files.sort! # sort to make sure the source's indexs match the targets

        # when no targets are specified, assume all targets
        source.targets = supervisor_actor_names if source.targets.empty?

        source.targets.lazily.each do | target_id |

          missing_files = []
          abandoned_files = []
          outdated_files = []

          MultiSync.debug "#{pluralize(source_files.length, 'file')} found from the source"

          MultiSync.debug 'Fetching files from the target...'

          target_files = Celluloid::Actor[target_id].files
          target_files.sort! # sort to make sure the target's indexs match the sources

          MultiSync.debug "#{pluralize(target_files.length, 'file')} found from the target"

          missing_files = determine_missing_files(source_files, target_files)
          missing_files_msg = "#{missing_files.length} of the files are missing"
          missing_files_msg += ", however we're skipping them as :upload_missing_files is false" unless MultiSync.upload_missing_files
          MultiSync.debug missing_files_msg

          abandoned_files = determine_abandoned_files(source_files, target_files)
          abandoned_files_msg = "#{abandoned_files.length} of the files are abandoned"
          abandoned_files_msg += ", however we're skipping them as :delete_abandoned_files is false" unless MultiSync.delete_abandoned_files
          MultiSync.debug abandoned_files_msg

          # remove missing_files from source_files ( as we know they are missing so don't need to check them )
          # remove abandoned_files from target_files ( as we know they are abandoned so don't need to check them )
          outdated_files = determine_outdated_files(source_files - missing_files, target_files - abandoned_files)
          MultiSync.debug "#{outdated_files.length} of the files are outdated"

          # abandoned files
          abandoned_files.lazily.each do | file |
            incomplete_jobs << { id: Celluloid.uuid, target_id: target_id, method: :delete, args: file }
          end if MultiSync.delete_abandoned_files

          # missing files
          missing_files.lazily.each do | file |
            incomplete_jobs << { id: Celluloid.uuid, target_id: target_id, method: :upload, args: file }
          end if MultiSync.upload_missing_files

          # outdated files
          outdated_files.lazily.each do | file |
            incomplete_jobs << { id: Celluloid.uuid, target_id: target_id, method: :upload, args: file }
          end

        end

      end
    end

    #
    def determine_missing_files(source_files, target_files)
      missing_files = (source_files - target_files)
      missing_files
    end

    #
    def determine_abandoned_files(source_files, target_files)
      abandoned_files = (target_files - source_files)
      abandoned_files
    end

    #
    def determine_outdated_files(source_files, target_files)
      outdated_files = []

      # TODO replace with celluloid pool of futures
      # check each source file against the matching target_file's etag
      source_files.lazily.each_with_index do |file, i|
        outdated_files << file unless !MultiSync.force && file.has_matching_etag?(target_files[i])
      end

      outdated_files
    end

    #
    def sync_attempted
      self.started_at = Time.now if first_run?
      self.sync_attempts = sync_attempts + 1
      if sync_attempts > MultiSync.max_sync_attempts
        MultiSync.warn "Sync was attempted more then #{MultiSync.max_sync_attempts} times"
        raise ArgumentError, "Sync was attempted more then #{MultiSync.max_sync_attempts} times"
      end
    end

    #
    def finish_sync
      incomplete_jobs.length != 0 ? synchronize : self.finished_at = Time.now
    end

    #
    def first_run?
      sync_attempts == 0
    end

    #
    def sync_pointless?
      sources.empty?
    end

    #
    def supervisor_actor_names
      supervisor.actors.map { |actor| actor.registered_name }
    end
  end
end
