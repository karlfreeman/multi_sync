# require "celluloid"
require "fog"
require "securerandom"
require "pathname"
require "multi_sync/remote_resource"

module MultiSync

  # Defines constants and methods related to the Target
  class Target
    # include Celluloid

    # An array of valid keys in the options hash when configuring a `MultiSync::Target`
    VALID_OPTIONS_KEYS = [
      :target_id,
      :target_dir,
      :destination_dir,
      :provider,
      :provider_credentials,
      :connection
    ].freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)
    
    # Initialize a new Target object
    #
    # @param options [Hash]
    def initialize(options = {})
      # raise(ArgumentError, "destination_dir must be present") unless options[:destination_dir]
      # raise(ArgumentError, "provider must be present and a symbol") unless options[:provider] && options[:provider].is_a?(Symbol)
      self.target_id = SecureRandom.uuid
      self.target_dir = Pathname.new(options.delete(:target_dir))
      self.destination_dir = Pathname.new(options.delete(:destination_dir))
      self.provider = options.delete(:provider).to_sym
      self.provider_credentials = options.delete(:provider_credentials) { {} }
      self.connection = Fog::Storage.new(self.provider_credentials.merge(:provider => self.provider))
    end

    #
    def files(*args)
      self.send("#{self.provider}_files".to_sym, *args) # based on the provider, get the files
    end

    private

    #
    def aws_files(with_root = false)
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

    #
    def local_files
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