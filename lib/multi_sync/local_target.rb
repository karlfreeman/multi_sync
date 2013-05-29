require "connection_pool"
require "fog"
require "pathname"
require "multi_sync/target"
require "multi_sync/remote_resource"

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

        connection.directories.get(self.destination_dir.to_s).files.each { |f|

          pathname = Pathname.new(f.key)

          #
          next if pathname.directory?

          files << MultiSync::RemoteResource.new(
            :with_root => self.target_dir + self.destination_dir + pathname,
            :without_root => pathname,
            :fog_file => f
          )

        }

      end

      return files
    end

  end

end