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
      self.file = options.delete(:file)
      self.path_with_root ||= options.delete(:with_root)
      self.path_without_root ||= options.delete(:without_root)
    end

    def body
      self.file.body
    end

    def content_length
      self.file.content_length
    end

    def etag
      begin
        self.file.etag
      rescue NoMethodError # fog local files don't have an MD5 etag
        Digest::MD5.hexdigest(File.read(self.path_with_root))
      end
    end

  end

end