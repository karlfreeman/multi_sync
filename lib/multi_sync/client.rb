require 'set'
require 'virtus'
require 'lazily'
require 'celluloid'
%w(sources targets helpers).each do |dir|
  Dir.glob(File.expand_path("../#{dir}/**/*.rb", __FILE__), &method(:require))
end

module MultiSync
  class Client
    include Virtus.model
    include MultiSync::Helpers::Pluralize

    attribute :supervisor, Celluloid::SupervisionGroup
    attribute :incomplete_jobs, Set, default: Set.new
    attribute :running_jobs, Set, default: Set.new
    attribute :complete_jobs, Set, default: Set.new
    attribute :sources, Array, default: []
    attribute :sync_attempts, Integer, default: 0
    attribute :file_sync_attempts, Integer, default: 0
    attribute :started_at, Time, required: false
    attribute :finished_at, Time, required: false

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(*args)
      self.supervisor = Celluloid::SupervisionGroup.run!
      super
    end

    def add_target(name, options = {})
      fail ArgumentError, "Duplicate target names detected, please rename '#{name}' to be unique" if supervisor_actor_names.include?(name)
      clazz = MultiSync.const_get("#{options[:type].capitalize}Target")
      supervisor.pool(clazz, as: name, args: [options], size: MultiSync.target_pool_size)
    rescue NameError
      MultiSync.warn "Unknown target type: #{options[:type]}"
      raise ArgumentError, "Unknown target type: #{options[:type]}"
    end
    alias_method :target, :add_target

    def add_source(name, options = {})
      clazz = MultiSync.const_get("#{options[:type].capitalize}Source")
      sources << clazz.new(options)
    rescue NameError
      MultiSync.warn "Unknown source type: #{options[:type]}"
      raise ArgumentError, "Unknown source type: #{options[:type]}"
    end
    alias_method :source, :add_source

    def synchronize
      MultiSync.warn 'Preventing synchronization as there are no sources found.' && return if sync_pointless?
      MultiSync.debug 'Starting synchronization...'

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
        rescue => error
          self.file_sync_attempts = file_sync_attempts + 1
          MultiSync.warn error.inspect
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

    def finalize
      if finished_at
        elapsed = finished_at.to_f - started_at.to_f
        minutes, seconds = elapsed.divmod 60.0
        bytes = complete_uploaded_jobs_bytes
        kilobytes = bytes / 1024.0
        MultiSync.debug "Sync completed in #{pluralize(minutes, 'minute')} and #{pluralize(seconds.round, 'second')}"
        MultiSync.debug 'The combined upload weight was ' + ((bytes > 1024.0) ? pluralize(kilobytes, 'kilobyte') : pluralize(bytes, 'byte'))
        MultiSync.debug "#{pluralize(file_sync_attempts, 'failed request')} were detected and re-tried"
      else
        MultiSync.debug "Sync failed to complete with #{pluralize(incomplete_jobs.length, 'outstanding file')} to be synchronised"
      end
      MultiSync.debug "#{pluralize(complete_jobs.length, 'file')} were synchronised (#{pluralize(complete_deleted_jobs.length, 'deleted file')} and #{pluralize(complete_uploaded_jobs.length, 'uploaded file')}) from #{pluralize(sources.length, 'source')} to #{pluralize(supervisor.actors.length, 'target')}"

      supervisor.finalize
    end
    alias_method :fin, :finalize

    def complete_deleted_jobs
      complete_jobs.select { |job| job[:method] == :delete }
    end

    def complete_uploaded_jobs
      complete_jobs.select { |job| job[:method] == :upload }
    end

    def complete_uploaded_jobs_bytes
      total_bytes = 0
      complete_uploaded_jobs.each do | job |
        total_bytes += job[:response].content_length || job[:response].determine_content_length || 0
      end
      total_bytes
    end

    private

    def determine_sync
      sources.lazily.each do |source|

        source_files = []

        starting_synchronizing_msg = "ynchronizing: '#{source.source_dir}'"
        starting_synchronizing_msg.prepend MultiSync.force ? 'Forcefully s' : 'S'
        MultiSync.debug starting_synchronizing_msg

        source_files = source.files
        source_files.sort! # sort to make sure the source's indexes match the targets

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

          missing_files.concat determine_missing_files(source_files, target_files)
          missing_files_msg = "#{missing_files.length} of the files are missing"
          missing_files_msg += ", however we're skipping them as :upload_missing_files is false" unless MultiSync.upload_missing_files
          MultiSync.debug missing_files_msg

          abandoned_files.concat determine_abandoned_files(source_files, target_files)
          abandoned_files_msg = "#{abandoned_files.length} of the files are abandoned"
          abandoned_files_msg += ", however we're skipping them as :delete_abandoned_files is false" unless MultiSync.delete_abandoned_files
          MultiSync.debug abandoned_files_msg

          # remove missing_files from source_files (as we know they are missing so don't need to check them)
          # remove abandoned_files from target_files (as we know they are abandoned so don't need to check them)
          outdated_files.concat determine_outdated_files(source_files - missing_files, target_files - abandoned_files)
          MultiSync.debug "#{outdated_files.length} of the files are outdated"

          # abandoned files
          if MultiSync.delete_abandoned_files
            abandoned_files.lazily.each do | file |
              incomplete_jobs << { id: Celluloid.uuid, target_id: target_id, method: :delete, args: file }
            end
          end

          # missing files
          if MultiSync.upload_missing_files
            missing_files.lazily.each do | file |
              incomplete_jobs << { id: Celluloid.uuid, target_id: target_id, method: :upload, args: file }
            end
          end

          # outdated files
          outdated_files.lazily.each do | file |
            incomplete_jobs << { id: Celluloid.uuid, target_id: target_id, method: :upload, args: file }
          end

        end

      end
    end

    def determine_missing_files(source_files, target_files)
      missing_files = (source_files - target_files)
      missing_files
    end

    def determine_abandoned_files(source_files, target_files)
      abandoned_files = (target_files - source_files)
      abandoned_files
    end

    def determine_outdated_files(source_files, target_files)
      outdated_files = []

      # TODO: replace with celluloid pool of futures
      # check each source file against the matching target_file's etag
      source_files.lazily.each_with_index do |file, i|
        outdated_files << file unless !MultiSync.force && file.matching_etag?(target_files[i])
      end

      outdated_files
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
      incomplete_jobs.length != 0 ? synchronize : self.finished_at = Time.now
    end

    def first_run?
      sync_attempts == 0
    end

    def sync_pointless?
      sources.empty?
    end

    def supervisor_actor_names
      supervisor.actors.map { |actor| actor.registered_name }
    end
  end
end
