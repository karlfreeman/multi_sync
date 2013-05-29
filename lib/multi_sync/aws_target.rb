require "fog"
require "pathname"
require "multi_sync/target"
require "multi_sync/remote_resource"

module MultiSync

  # Defines constants and methods related to the AWSTarget
  class AWSTarget < Target
    
    # Initialize a new AWSTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(options)
      self.connection = ConnectionPool.new(:size => Parallel.processor_count, :timeout => 5) { 
        Fog::Storage.new(self.credentials.merge(:provider => :aws))
      }
    end

    #
    def files
      files = []

      self.connection.with do |connection|

        connection.directories.get(self.target_dir.to_s, :prefix => self.destination_dir.to_s).files.each { |f|

          pathname = Pathname.new(f.key)

          # directory || overreaching AWS globbing
          next if (pathname.to_s =~ /\/$/) || !(pathname.to_s =~ /^#{self.destination_dir.to_s}\//)

          files << MultiSync::RemoteResource.new(
            :with_root => self.target_dir + pathname,
            :without_root => (self.destination_dir != "") ? pathname.relative_path_from(self.destination_dir).cleanpath : pathname,
            :fog_file => f
          )

        }

      end

      return files
    end

  end

end