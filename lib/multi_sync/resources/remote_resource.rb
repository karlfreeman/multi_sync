require "pathname"
require "digest/md5"
require "multi_sync/resource"

module MultiSync

  # Defines constants and methods related to the RemoteResource
  class RemoteResource < Resource

    # Initialize a new RemoteResource object
    #
    # @param path [String]
    def initialize(options = {})
      self.file = options.fetch(:file, nil)
      super(options)
    end

    #
    def body
      self.file.body
    end

    #
    def determine_etag
      begin
        self.file.etag
      rescue NoMethodError # Fog::Storage::Local::File's don't have an etag method :(
        Digest::MD5.hexdigest(File.read(self.path_with_root))
      end
    end

    #
    def determine_mtime
      self.file.last_modified
    end

    #
    def determine_content_type
      self.file.content_type
    end

    #
    def determine_content_length
      self.file.content_length
    end

  end

end