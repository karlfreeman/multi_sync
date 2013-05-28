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
      self.connection = Fog::Storage.new(self.credentials.merge(:provider => :aws))
    end

    #
    def files
      files = []

      self.connection.directories.get(self.target_dir.to_s, :prefix => self.destination_dir.to_s).files.each { |f|
        files << Pathname.new(f.key)
      }

      files.reject!{ |pathname|
        (pathname.to_s =~ /\/$/) || # directory
        !(pathname.to_s =~ /^#{self.destination_dir.to_s}\//) # overreaching AWS globbing
      }

      files.map!{ |pathname|

        resource_options = {
          :with_root => self.target_dir + pathname
        }

        if self.destination_dir != ""
          resource_options[:without_root] = pathname.relative_path_from(self.destination_dir).cleanpath
        else
          resource_options[:without_root] = pathname
        end

        MultiSync::RemoteResource.new(resource_options)
      }

      return files
    end

  end

end