require "fog"
require "lazily"
require "pathname"
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
      self.connection = ::Fog::Storage.new(self.credentials.merge(:provider => :local))
    end

    #
    def files
      files = []

      directory = self.connection.directories.get(self.destination_dir.to_s)
      return if directory.nil?

      directory.files.lazily.each { |file|

        pathname = Pathname.new(file.key)

        # directory
        next if pathname.directory?

        MultiSync.debug "Found RemoteResource:'#{pathname.to_s}' from #{self.class_name}:'#{File.join(self.connection.local_root, self.destination_dir)}'"

        files << MultiSync::RemoteResource.new(
          :file => file,
          :with_root => self.target_dir + self.destination_dir + pathname,
          :without_root => pathname
        )

      }

      return files
    end

    #
    def upload(resource)

      key = resource.path_without_root.to_s
      MultiSync.debug "Upload #{resource.class_name}:'#{key}' to #{self.class_name}:'#{File.join(self.connection.local_root, self.destination_dir)}'"
      directory = self.connection.directories.get(self.destination_dir.to_s)
      return if directory.nil?
      directory.files.create(
        :key => key,
        :body => resource.body
      )

    end

    #
    def delete(resource)

      key = resource.path_without_root.to_s
      MultiSync.debug "Delete #{resource.class_name}:'#{key}' from #{self.class_name}:'#{File.join(self.connection.local_root, self.destination_dir)}'"
      self.connection.directories.get(self.destination_dir.to_s).files.get(key).destroy

    end

  end

end