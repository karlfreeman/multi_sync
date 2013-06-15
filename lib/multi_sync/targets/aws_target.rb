require "fog"
require "lazily"
require "pathname"
require "multi_sync/target"
require "multi_sync/resources/remote_resource"

module MultiSync

  # Defines constants and methods related to the AwsTarget
  class AwsTarget < Target
    
    # Initialize a new AwsTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      cloned_options = Marshal.load(Marshal.dump(options)) # deep clone options
      super(cloned_options)
      self.connection = ::Fog::Storage.new(self.credentials.merge(:provider => :aws))
    end

    #
    def files
      files = []

      directory = self.connection.directories.get(self.target_dir.to_s, :prefix => self.destination_dir.to_s)
      return if directory.nil?

      directory.files.lazily.each { |file|

        pathname = Pathname.new(file.key)

        # eg directory or overreaching AWS globbing
        next unless valid_path?(pathname)

        files << MultiSync::RemoteResource.new(
          :with_root => self.target_dir + pathname, # pathname seems to already have the prefix ( destination_dir )
          :without_root => (self.destination_dir != "") ? pathname.relative_path_from(self.destination_dir).cleanpath : pathname,
          :fog_file => file
        )

      }

      return files
    end

    #
    def upload(resource)

      MultiSync.log "Upload #{resource.class.to_s.split('::').last}:'#{resource.path_without_root.to_s}' to #{self.class.to_s.split('::').last}:'/#{(self.target_dir + self.destination_dir).to_s}'"
      directory = self.connection.directories.get(self.target_dir.to_s)
      return if directory.nil?
      directory.files.create(
        :key => (self.destination_dir + resource.path_without_root).to_s,
        :body => resource.body
      )

    end

    #
    def delete(resource)

      MultiSync.log "Delete #{resource.class.to_s.split('::').last}:'#{resource.path_without_root.to_s}' from #{self.class.to_s.split('::').last}:'/#{(self.target_dir + self.destination_dir).to_s}'"
      self.connection.delete_object(self.target_dir.to_s, (self.destination_dir + resource.path_without_root).to_s)

    end

    private


    # directory or overreaching AWS globbing
    def valid_path?(pathname)

      # directory
      return false if pathname.to_s =~ /\/$/
      # overreaching AWS globbing
      return false if !self.destination_dir.to_s.empty? && !(pathname.to_s =~ /^#{self.destination_dir.to_s}\//)

      return true

    end

  end

end