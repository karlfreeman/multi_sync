require "fog"
require "pathname"
require "connection_pool"
require "multi_sync/target"
require "multi_sync/resources/remote_resource"

module MultiSync

  # Defines constants and methods related to the AWSTarget
  class AWSTarget < Target
    
    # Initialize a new AWSTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(options)
      self.connection = ConnectionPool.new(:size => 1, :timeout => 5) { 
        Fog::Storage.new(self.credentials.merge(:provider => :aws))
      }
    end

    #
    def files
      files = []

      self.connection.with do |connection|

        connection.directories.get(self.target_dir.to_s, :prefix => self.destination_dir.to_s).files.each { |file|

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

    def sync(resource)

      self.connection.with do |connection|
        connection.directories.get(self.target_dir.to_s).files.create(
          :key => (self.destination_dir + resource.path_without_root).to_s,
          :body => "Hello World!"
        )
      end

    end

  end

end