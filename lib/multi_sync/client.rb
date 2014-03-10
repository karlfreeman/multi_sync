require 'virtus'
require 'celluloid'
%w(sources targets helpers).each do |dir|
  Dir.glob(File.expand_path("../#{dir}/**/*.rb", __FILE__), &method(:require))
end

module MultiSync
  class Client
    include Virtus.model
    include MultiSync::Helpers::Pluralize

    attribute :supervisor, Celluloid::SupervisionGroup
    attribute :running_upload_jobs, Array, default: []
    attribute :running_delete_jobs, Array, default: []
    attribute :complete_upload_jobs, Array, default: []
    attribute :complete_delete_jobs, Array, default: []
    attribute :incomplete_upload_jobs, Array, default: []
    attribute :incomplete_delete_jobs, Array, default: []
    attribute :sources, Array, default: []
    attribute :sync_attempts, Integer, default: 0
    attribute :file_sync_attempts, Integer, default: 0
    attribute :started_at, Time, required: false
    attribute :finished_at, Time, required: false

    SUPPORTED_SOURCE_TYPES = [[:local, MultiSync::LocalSource], [:manifest, MultiSync::ManifestSource]]
    SUPPORTED_TARGET_TYPES = [[:local, MultiSync::LocalTarget], [:aws, MultiSync::AwsTarget]]

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(*args)
      self.supervisor = Celluloid::SupervisionGroup.run!
      super
    end

    #
    #
    #
    def add_target(clazz, options = {})
      # TODO: friendly pool names?
      pool_name = Celluloid.uuid
      supervisor.pool(clazz, as: pool_name, args: [options], size: MultiSync.target_pool_size)
      pool_name
    end

    #
    #
    #
    def add_source(clazz, options = {})
      source = clazz.new(options)
      sources << source
      source
    end

    #
    #
    #
    def sync
      MultiSync.warn 'Preventing synchronization as there are no sources found.' && return if sync_pointless?

      if first_run?
        MultiSync.debug 'Starting synchronization...'
        determine_sync
      else
        MultiSync.debug 'Restarting synchronization...'
      end

      sync_attempted

      MultiSync.debug 'Fetching upload jobs from the future...'
      (running_upload_jobs | incomplete_upload_jobs).each do | job |
        begin
          complete_upload_jobs << job.value
        rescue => error
          self.file_sync_attempts = file_sync_attempts + 1
          MultiSync.warn error.inspect
          incomplete_upload_jobs << job
        end
      end

      MultiSync.debug 'Fetching delete jobs from the future...'
      (running_delete_jobs | incomplete_delete_jobs).each do | job |
        begin
          complete_delete_jobs << job.value
        rescue => error
          self.file_sync_attempts = file_sync_attempts + 1
          MultiSync.warn error.inspect
          incomplete_delete_jobs << job
        end
      end

      finish_sync
    end

    private

    def determine_sync
      sources.each do |source|

        source_files = []

        starting_synchronizing_msg = "ynchronizing: '#{source.source_dir}'"
        starting_synchronizing_msg.prepend MultiSync.force ? 'Forcefully s' : 'S'
        MultiSync.debug starting_synchronizing_msg

        source_files = source.files

        # when no targets are specified, assume all targets
        source.targets = supervisor_actor_names if source.targets.empty?

        source.targets.each do | target_id |

          missing_files = []
          abandoned_files = []
          outdated_files = []

          MultiSync.debug "#{pluralize(source_files.length, 'file')} found from the source"

          MultiSync.debug 'Fetching files from the target...'

          target_files = supervisor[target_id].files
          target_files.sort! # sort to make sure the target's indexs match the sources

          MultiSync.debug "#{pluralize(target_files.length, 'file')} found from the target"

          missing_files.concat determine_missing_files(source_files, target_files)
          missing_files_msg = "#{missing_files.length} of the files are missing"
          missing_files_msg += ", however we're skipping them as :upload_missing_files is false" unless MultiSync.upload_missing_files
          MultiSync.debug missing_files_msg

          abandoned_files.concat determine_abandoned_files(source_files, target_files)
          abandoned_files_msg = "#{abandoned_files.length} of the files are abandoned"
          abandoned_files_msg += ", however we're skipping them as :delete_abandoned_files is false" unless MultiSync.delete_abandoned_files
          MultiSync.debug abandoned_files_msg

          # remove missing_files from source_files (as we know they're missing so don't need to check for them)
          # remove abandoned_files from target_files (as we know they're abandoned so don't need to check for them)
          outdated_files.concat determine_outdated_files(source_files - missing_files, target_files - abandoned_files)
          MultiSync.debug "#{outdated_files.length} of the files are outdated"

          MultiSync.debug 'Scheduling jobs in the future...'

          # outdated files
          outdated_files.each do | resource |
            running_upload_jobs << supervisor[target_id].future.upload(resource)
          end

          # missing files
          if MultiSync.upload_missing_files
            missing_files.each do | resource |
              running_upload_jobs << supervisor[target_id].future.upload(resource)
            end
          end

          # abandoned files
          if MultiSync.delete_abandoned_files
            abandoned_files.each do | resource |
              running_delete_jobs << supervisor[target_id].future.delete(resource)
            end
          end

        end

      end
    end

    def sync_attempted
      self.started_at = Time.now if first_run?
      self.sync_attempts = sync_attempts.next
      if sync_attempts > MultiSync.max_sync_attempts
        MultiSync.warn "Sync was attempted more then #{MultiSync.max_sync_attempts} times"
        fail ArgumentError, "Sync was attempted more then #{MultiSync.max_sync_attempts} times"
      end
    end

    def finish_sync
      # recurse when there are incomplete_jobs still
      incomplete_jobs.length != 0 ? sync : self.finished_at = Time.now

      if finished_at
        elapsed = finished_at.to_f - started_at.to_f
        minutes, seconds = elapsed.divmod 60.0
        bytes = complete_upload_jobs_bytes
        kilobytes = bytes / 1024.0
        MultiSync.debug "Sync completed in #{pluralize(minutes.round, 'minute')} and #{pluralize(seconds.round, 'second')}"
        MultiSync.debug 'The combined upload weight was ' + ((bytes > 1024.0) ? pluralize(kilobytes.round, 'kilobyte') : pluralize(bytes.round, 'byte'))
        MultiSync.debug "#{pluralize(file_sync_attempts, 'failed request')} were detected and re-tried"
      else
        MultiSync.debug "Sync failed to complete with #{pluralize(incomplete_jobs.length, 'outstanding file')} to be synchronised"
      end
      MultiSync.debug "#{pluralize(complete_jobs.length, 'file')} were synchronised (#{pluralize(complete_delete_jobs.length, 'deleted file')} and #{pluralize(complete_upload_jobs.length, 'uploaded file')}) from #{pluralize(sources.length, 'source')} to #{pluralize(supervisor_actor_names.length, 'target')}"

      supervisor.terminate
    end

    def complete_jobs
      complete_upload_jobs | complete_delete_jobs
    end

    def incomplete_jobs
      incomplete_upload_jobs | incomplete_delete_jobs
    end

    def complete_upload_jobs_bytes
      total_bytes = 0
      complete_upload_jobs.each do | job |
        total_bytes += job.content_length || job.determine_content_length || 0
      end
      total_bytes
    end

    def determine_missing_files(source_files, target_files)
      source_files - target_files
    end

    def determine_abandoned_files(source_files, target_files)
      target_files - source_files
    end

    def determine_outdated_files(source_files, target_files)
      outdated_files = []
      equivalent_files = []

      # TODO: replace with celluloid pool of futures
      # check each source file against the matching target_file's etag
      source_files.each_with_index do |file, i|
        if !file.matching_etag?(target_files[i]) || MultiSync.force
          outdated_files << file
        else
          equivalent_files << file
        end
      end

      # TODO: move to a better place
      MultiSync.debug "#{equivalent_files.length} of the files are identical"

      outdated_files
    end

    def first_run?
      sync_attempts == 0
    end

    def sync_pointless?
      sources.empty?
    end

    def supervisor_actor_names
      supervisor.actors.map(&:registered_name)
    end
  end
end
