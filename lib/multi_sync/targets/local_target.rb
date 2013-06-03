require "fog"
require "lazily"
require "pathname"
require "connection_pool"
require "multi_sync/target"
require "multi_sync/resources/remote_resource"

module MultiSync

  # Defines constants and methods related to the LocalTarget
  class LocalTarget < Target
    
    # Initialize a new LocalTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(options)
      self.connection = ConnectionPool.new(:size => MultiSync.concurrency, :timeout => 5) { 
        Fog::Storage.new(self.credentials.merge(:provider => :local))
      }
    end

    #
    def files
      files = []

      self.connection.with do |connection|

        directory = connection.directories.get(self.destination_dir.to_s)
        next if directory.nil?

        directory.files.lazily.each { |file|

          pathname = Pathname.new(file.key)

          # directory
          next if pathname.directory?

          MultiSync.log "Found RemoteResource:'#{pathname.to_s}' from #{self.class.to_s.split('::').last}:'#{(Pathname.new(connection.local_root) + self.destination_dir).to_s}'"

          files << MultiSync::RemoteResource.new(
            :with_root => self.target_dir + self.destination_dir + pathname,
            :without_root => pathname,
            :fog_file => file
          )

        }

      end

      return files
    end

    #
    def upload(resource)

      self.connection.with do |connection|
        key = resource.path_without_root.to_s
        MultiSync.log "Upload #{resource.class.to_s.split('::').last}:'#{key}' to #{self.class.to_s.split('::').last}:'#{(Pathname.new(connection.local_root) + self.destination_dir).to_s}'"
        directory = connection.directories.get(self.destination_dir.to_s)
        next if directory.nil?
        directory.files.create(
          :key => key,
          :body => resource.body
        )
      end

    end

    #
    def delete(resource)

      self.connection.with do |connection|
        key = resource.path_without_root.to_s
        MultiSync.log "Delete #{resource.class.to_s.split('::').last}:'#{key}' from #{self.class.to_s.split('::').last}:'#{(Pathname.new(connection.local_root) + self.destination_dir).to_s}'"
        connection.directories.get(self.destination_dir.to_s).files.get(key).destroy
      end

    end

  end

end