require "fog"
require "lazily"
require "pathname"
require "connection_pool"
require "multi_sync/target"
require "multi_sync/resources/remote_resource"

module MultiSync

  # Defines constants and methods related to the AwsTarget
  class AwsTarget < Target
    
    # Initialize a new AwsTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(Marshal.load(Marshal.dump(options))) # deep clone options
      self.connection = ConnectionPool.new(:size => MultiSync.concurrency, :timeout => 5) { 
        Fog::Storage.new(self.credentials.merge(:provider => :aws))
      }
    end

    #
    def files
      files = []

      self.connection.with do |connection|

        directory = connection.directories.get(self.target_dir.to_s, :prefix => self.destination_dir.to_s)
        next if directory.nil?

        directory.files.lazily.each { |file|

          pathname = Pathname.new(file.key)

          # directory || overreaching AWS globbing
          next if (pathname.to_s =~ /\/$/) || !(pathname.to_s =~ /^#{self.destination_dir.to_s}\//)

          files << MultiSync::RemoteResource.new(
            :with_root => self.target_dir + pathname, # pathname seems to already have the prefix ( destination_dir )
            :without_root => (self.destination_dir != "") ? pathname.relative_path_from(self.destination_dir).cleanpath : pathname,
            :fog_file => file
          )

        }

      end

      return files
    end

    #
    def upload(resource)

      self.connection.with do |connection|
        MultiSync.log "Upload #{resource.class.to_s.split('::').last}:'#{resource.path_without_root.to_s}' to #{self.class.to_s.split('::').last}:'/#{(self.target_dir + self.destination_dir).to_s}'"
        directory = connection.directories.get(self.target_dir.to_s)
        next if directory.nil?
        directory.files.create(
          :key => (self.destination_dir + resource.path_without_root).to_s,
          :body => resource.body
        )
      end

    end

    #
    def delete(resource)

      self.connection.with do |connection|
        MultiSync.log "Delete #{resource.class.to_s.split('::').last}:'#{resource.path_without_root.to_s}' from #{self.class.to_s.split('::').last}:'/#{(self.target_dir + self.destination_dir).to_s}'"
        connection.delete_object(self.target_dir.to_s, (self.destination_dir + resource.path_without_root).to_s)
      end

    end

  end

end