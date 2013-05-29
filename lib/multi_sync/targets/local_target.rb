require "fog"
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
      self.connection = ConnectionPool.new(:size => 1, :timeout => 5) { 
        Fog::Storage.new(self.credentials.merge(:provider => :local))
      }
    end

    #
    def files
      files = []

      self.connection.with do |connection|

        connection.directories.get(self.destination_dir.to_s).files.each { |file|

          pathname = Pathname.new(file.key)

          # directory
          next if pathname.directory?

          files << MultiSync::RemoteResource.new(
            :with_root => self.target_dir + self.destination_dir + pathname,
            :without_root => pathname,
            :fog_file => file
          )

        }

      end

      return files
    end

    def sync(resource)

      self.connection.with do |connection|
        connection.directories.get(self.destination_dir.to_s).files.create(
          :key => resource.path_without_root.to_s,
          :body => 'Hello World!'
        )
      end

    end

  end

end