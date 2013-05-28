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
      self.connection = Fog::Storage.new(self.credentials.merge(:provider => :local))
    end

    #
    def files
      files = []

      self.connection.directories.get(self.destination_dir.to_s).files.each { |f|
        files << Pathname.new(f.key)
      }

      files.reject!{ |pathname| pathname.directory? }

      files.map!{ |pathname|
        MultiSync::RemoteResource.new(
          :with_root => self.target_dir + self.destination_dir + pathname,
          :without_root => pathname
        )
      }

      return files
    end

  end

end